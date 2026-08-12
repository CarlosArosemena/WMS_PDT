-- M-INTEL WMS RF - operaciones críticas transaccionales
-- Ejecutar después del schema principal del WMS.

create or replace function public.rf_receive(
  p_pedido_id uuid,
  p_sku text,
  p_qty numeric,
  p_wh_id text,
  p_ubicacion text default null,
  p_lote text default null,
  p_vencimiento date default null,
  p_usuario text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  l_line pe_lineas%rowtype;
  l_ped pedidos_entrada%rowtype;
  l_stock stock%rowtype;
  l_new numeric;
  l_estado text;
  l_desc text;
begin
  if coalesce(p_qty,0) <= 0 then raise exception 'La cantidad debe ser mayor que cero'; end if;

  select * into l_ped from pedidos_entrada where id=p_pedido_id for update;
  if not found then raise exception 'Pedido de entrada no existe'; end if;
  if l_ped.estado not in ('Liberado','En proceso') then
    raise exception 'Pedido % no está disponible para recepción: %', l_ped.numero, l_ped.estado;
  end if;

  select * into l_line from pe_lineas where pedido_id=p_pedido_id and sku=p_sku order by created_at limit 1 for update;
  if not found then raise exception 'SKU % no pertenece al pedido', p_sku; end if;

  if p_qty > greatest(l_line.cantidad_ped-coalesce(l_line.cantidad_rec,0),0) then
    raise exception 'Cantidad % supera el pendiente de % para %', p_qty, greatest(l_line.cantidad_ped-coalesce(l_line.cantidad_rec,0),0), p_sku;
  end if;

  select * into l_stock from stock where sku=p_sku and wh_id=p_wh_id for update;
  if found then
    l_new := coalesce(l_stock.disponible,0)+p_qty;
    update stock set disponible=l_new, ubicacion=coalesce(p_ubicacion,ubicacion), lote=coalesce(p_lote,lote), vencimiento=coalesce(p_vencimiento,vencimiento), updated_at=now() where id=l_stock.id;
  else
    select descripcion into l_desc from articulos where codigo=p_sku limit 1;
    l_new := p_qty;
    insert into stock(sku,descripcion,wh_id,disponible,reservado,ubicacion,lote,vencimiento) values(p_sku,coalesce(l_desc,p_sku),p_wh_id,p_qty,0,p_ubicacion,p_lote,p_vencimiento);
  end if;

  update pe_lineas
     set cantidad_rec=coalesce(cantidad_rec,0)+p_qty,
         lote=coalesce(p_lote,lote),
         vencimiento=coalesce(p_vencimiento,vencimiento),
         estado=case when coalesce(cantidad_rec,0)+p_qty >= cantidad_ped then 'Completado' else 'Parcial' end
   where id=l_line.id;

  if not exists(select 1 from pe_lineas where pedido_id=p_pedido_id and coalesce(cantidad_rec,0)<cantidad_ped) then
    l_estado := 'Completado';
  else
    l_estado := 'En proceso';
  end if;

  update pedidos_entrada set estado=l_estado, updated_at=now() where id=p_pedido_id;

  insert into movimientos(tipo,referencia,wh_id,sku,cantidad,ubicacion,notas,usuario)
  values('ENTRADA_RF',l_ped.numero,p_wh_id,p_sku,p_qty,p_ubicacion,'Recepción RF',p_usuario);

  return jsonb_build_object('ok',true,'pedido_id',p_pedido_id,'sku',p_sku,'cantidad',p_qty,'stock',l_new,'estado_pedido',l_estado);
end;
$$;

create or replace function public.rf_pick(
  p_task_id uuid,
  p_qty numeric,
  p_usuario text default null,
  p_scan_sku text default null,
  p_scan_ubicacion text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  l_task rf_tasks%rowtype;
  l_stk stock%rowtype;
  l_new_done numeric;
  l_new_stock numeric;
  l_restante numeric;
  l_all_done boolean;
begin
  if coalesce(p_qty,0) <= 0 then raise exception 'La cantidad de picking debe ser mayor que cero'; end if;

  select * into l_task from rf_tasks where id=p_task_id for update;
  if not found then raise exception 'Tarea RF no existe'; end if;
  if l_task.estado not in ('pendiente','en_proceso') then raise exception 'Tarea no disponible: %',l_task.estado; end if;
  if p_scan_sku is not null and upper(trim(p_scan_sku)) <> upper(trim(l_task.sku)) then raise exception 'SKU escaneado % no coincide con %',p_scan_sku,l_task.sku; end if;
  if p_scan_ubicacion is not null and l_task.ubicacion is not null and upper(trim(p_scan_ubicacion)) <> upper(trim(l_task.ubicacion)) then raise exception 'Ubicación escaneada % no coincide con %',p_scan_ubicacion,l_task.ubicacion; end if;

  l_restante := greatest(coalesce(l_task.cantidad,0)-coalesce(l_task.completada,0),0);
  if p_qty > l_restante then raise exception 'Cantidad % supera el pendiente %',p_qty,l_restante; end if;

  select * into l_stk from stock where sku=l_task.sku and wh_id=l_task.wh_id for update;
  if not found then raise exception 'No existe stock para % en %',l_task.sku,l_task.wh_id; end if;
  if coalesce(l_stk.disponible,0) < p_qty then raise exception 'Stock insuficiente: disponible %, solicitado %',l_stk.disponible,p_qty; end if;

  l_new_stock := l_stk.disponible-p_qty;
  update stock set disponible=l_new_stock, reservado=greatest(0,coalesce(reservado,0)-p_qty), updated_at=now() where id=l_stk.id;

  l_new_done := coalesce(l_task.completada,0)+p_qty;
  update rf_tasks set completada=l_new_done, estado=case when l_new_done>=cantidad then 'completado' else 'en_proceso' end, operador=coalesce(p_usuario,operador) where id=l_task.id;

  insert into movimientos(tipo,referencia,wh_id,sku,cantidad,ubicacion,notas,usuario)
  values('PICKING_RF',p_task_id::text,l_task.wh_id,l_task.sku,p_qty,l_task.ubicacion,'Picking RF transaccional',p_usuario);

  return jsonb_build_object('ok',true,'task_id',l_task.id,'sku',l_task.sku,'cantidad',p_qty,'completada',l_new_done,'cantidad_tarea',l_task.cantidad,'stock',l_new_stock,'estado',case when l_new_done>=l_task.cantidad then 'completado' else 'en_proceso' end);
end;
$$;

create or replace function public.rf_relocate(
  p_sku text,
  p_wh_id text,
  p_qty numeric,
  p_origen text,
  p_destino text,
  p_usuario text default null,
  p_motivo text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  l_stock stock%rowtype;
  l_dest ubicaciones%rowtype;
  l_ori ubicaciones%rowtype;
begin
  if p_origen is null or p_destino is null or p_origen=p_destino then raise exception 'Origen y destino inválidos'; end if;
  if coalesce(p_qty,0)<=0 then raise exception 'Cantidad inválida'; end if;
  select * into l_stock from stock where sku=p_sku and wh_id=p_wh_id and ubicacion=p_origen for update;
  if not found then raise exception 'No existe stock % en %',p_sku,p_origen; end if;
  if l_stock.disponible < p_qty then raise exception 'Stock insuficiente en origen'; end if;
  select * into l_dest from ubicaciones where codigo=p_destino and activo=true for update;
  if not found then raise exception 'Ubicación destino no existe'; end if;
  select * into l_ori from ubicaciones where codigo=p_origen and activo=true for update;
  if not found then raise exception 'Ubicación origen no existe'; end if;

  update stock set ubicacion=p_destino, updated_at=now() where id=l_stock.id;
  update ubicaciones set ocupada=true, estado='busy' where id=l_dest.id;
  if not exists(select 1 from stock where wh_id=p_wh_id and ubicacion=p_origen and disponible>0) then
    update ubicaciones set ocupada=false, estado='free' where id=l_ori.id;
  end if;
  insert into movimientos(tipo,wh_id,sku,cantidad,ubicacion,notas,usuario) values('REUBICACION',p_wh_id,p_sku,p_qty,p_destino,coalesce(p_motivo,'Reubicación RF')||' · origen '||p_origen,p_usuario);
  return jsonb_build_object('ok',true,'sku',p_sku,'cantidad',p_qty,'origen',p_origen,'destino',p_destino);
end;
$$;

create or replace function public.rf_adjust(
  p_stock_id uuid,
  p_tipo text,
  p_qty numeric,
  p_wh_id text,
  p_usuario text default null,
  p_motivo text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  l_stock stock%rowtype;
  l_new numeric;
  l_delta numeric;
begin
  select * into l_stock from stock where id=p_stock_id and wh_id=p_wh_id for update;
  if not found then raise exception 'Registro de stock no existe'; end if;
  if coalesce(p_qty,0)<0 then raise exception 'Cantidad inválida'; end if;
  l_new := l_stock.disponible;
  if p_tipo='ENTRADA' then l_new:=l_new+p_qty;
  elsif p_tipo in ('SALIDA','DANADO','PERDIDA') then l_new:=greatest(0,l_new-p_qty);
  elsif p_tipo='CORRECCION' then l_new:=p_qty;
  else raise exception 'Tipo de ajuste inválido'; end if;
  l_delta:=l_new-l_stock.disponible;
  update stock set disponible=l_new, updated_at=now() where id=l_stock.id;
  insert into movimientos(tipo,wh_id,sku,cantidad,ubicacion,notas,usuario) values('AJUSTE_'||p_tipo,p_wh_id,l_stock.sku,l_delta,l_stock.ubicacion,coalesce(p_motivo,'Ajuste RF'),p_usuario);
  return jsonb_build_object('ok',true,'sku',l_stock.sku,'anterior',l_stock.disponible,'nuevo',l_new,'delta',l_delta);
end;
$$;

grant execute on function public.rf_receive(uuid,text,numeric,text,text,text,date,text) to anon, authenticated;
grant execute on function public.rf_pick(uuid,numeric,text,text,text) to anon, authenticated;
grant execute on function public.rf_relocate(text,text,numeric,text,text,text,text) to anon, authenticated;
grant execute on function public.rf_adjust(uuid,text,numeric,text,text,text) to anon, authenticated;
