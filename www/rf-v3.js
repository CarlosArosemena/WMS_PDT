/*
 * M-INTEL WMS RF v3
 * Correcciones de lógica para el schema M-INTEL WMS Pro.
 * Este archivo se carga después del cliente RF original y reemplaza
 * las operaciones críticas por RPC transaccionales.
 */
(function () {
  const wait = (fn) => document.readyState === 'loading'
    ? document.addEventListener('DOMContentLoaded', fn, { once: true })
    : fn();

  function rpcError(error) {
    if (error) {
      const msg = error.message || error.details || 'Error de operación';
      if (typeof toast === 'function') toast(msg, 'err');
      return true;
    }
    return false;
  }

  // No se aceptan contraseñas demo. La identidad operativa es el operador
  // seleccionado y su almacén autorizado. El esquema puede evolucionar a
  // Supabase Auth/PIN sin tocar la lógica transaccional.
  window.loginConfirm = function loginConfirmV3() {
    const idx = window._loginSelIdx;
    if (idx === null || idx === undefined) {
      toast('Selecciona un operador', 'warn');
      return;
    }
    const u = window._loginUsers?.[idx];
    if (!u) {
      toast('Operador no disponible', 'err');
      return;
    }
    if (u.activo === false) {
      toast('El operador está inactivo', 'err');
      return;
    }

    sesion = {
      id: u.id,
      nombre: u.nombre,
      iniciales: u.iniciales || (u.nombre || 'OP').split(' ').map(x => x[0]).join('').slice(0, 2).toUpperCase(),
      rol: u.modulo || 'Operador',
      wh_id: u.wh_id || ''
    };
    localStorage.setItem('rf_sesion', JSON.stringify(sesion));
    el('login-screen').classList.add('off');
    el('login-pass').value = '';
    initApp();
  };

  // Respeta el almacén asignado al operador. Si no existe, usa el primer WH activo.
  window.detectarAlmacen = async function detectarAlmacenV3() {
    if (!db) return;
    let q = db.from('almacenes').select('id,codigo,nombre').eq('activo', true).order('codigo');
    if (sesion?.wh_id) q = q.eq('codigo', sesion.wh_id);
    const { data, error } = await q.limit(1);
    if (error) {
      toast('No se pudo determinar el almacén: ' + error.message, 'err');
      return;
    }
    if (data?.length) {
      whActivo = data[0].id;
      wh_codigo = data[0].codigo;
    } else if (sesion?.wh_id) {
      toast('El operador no tiene un almacén activo válido: ' + sesion.wh_id, 'err');
    }
  };

  // Tareas RF reales. No se crean tareas ficticias desde ps_lineas.
  window.loadPedidosParaPicking = async function loadPedidosParaPickingV3() {
    if (!db) return;
    let q = db.from('rf_tasks')
      .select('id,sku,descripcion,ubicacion,cantidad,completada,estado,operador,wh_id,wave_id,created_at')
      .in('estado', ['pendiente', 'en_proceso'])
      .order('created_at');

    if (wh_codigo) q = q.eq('wh_id', wh_codigo);
    const { data, error } = await q;
    if (error) { rpcError(error); return; }

    const s = el('pick-pedido');
    if (!s) return;

    const tasks = data || [];
    // Conservamos el selector existente, pero ahora representa la tarea/wave RF.
    s.innerHTML = '<option value="">— Seleccionar tarea RF —</option>' +
      tasks.map(t => `<option value="${t.id}">${t.sku} · ${t.ubicacion || 'Sin ubicación'} · ${Math.max(0, Number(t.cantidad || 0) - Number(t.completada || 0))} uds</option>`).join('');
  };

  window.loadPicking = async function loadPickingV3() {
    const taskId = v('pick-pedido');
    if (!taskId) {
      el('pick-task-wrap').style.display = 'none';
      return;
    }
    if (!db) return;

    const { data: t, error } = await db.from('rf_tasks')
      .select('id,sku,descripcion,ubicacion,cantidad,completada,estado,operador,wh_id,wave_id')
      .eq('id', taskId).single();

    if (error || !t) { rpcError(error || new Error('Tarea no encontrada')); return; }
    if (t.wh_id && wh_codigo && t.wh_id !== wh_codigo) {
      toast('La tarea pertenece a otro almacén', 'err');
      return;
    }

    pickTasks = [t];
    pickDone = [];
    pickIdx = 0;
    el('pick-task-wrap').style.display = 'block';
    renderPickTaskV3(t);
  };

  function renderPickTaskV3(t) {
    const restante = Math.max(0, Number(t.cantidad || 0) - Number(t.completada || 0));
    el('pk-loc').textContent = t.ubicacion || '—';
    el('pk-sku').textContent = t.sku;
    el('pk-desc').textContent = t.descripcion || '';
    el('pk-qty').textContent = restante;
    el('pk-conf').value = restante;
    el('pk-conf').max = restante;
    el('pk-prog-lbl').textContent = `${Number(t.completada || 0)} / ${Number(t.cantidad || 0)} uds`;
    const pct = Number(t.cantidad || 0) > 0 ? Math.round(Number(t.completada || 0) / Number(t.cantidad) * 100) : 0;
    el('pk-prog-pct').textContent = pct + '%';
    el('pk-prog-bar').style.width = pct + '%';
    el('pk-lines-done').innerHTML = t.estado === 'en_proceso'
      ? '<div class="al warn">Tarea en proceso. Confirma la cantidad restante.</div>' : '';
  }

  window.confirmarPicking = async function confirmarPickingV3() {
    const taskId = v('pick-pedido');
    if (!taskId) { toast('Selecciona una tarea RF', 'warn'); return; }
    const t = pickTasks?.[0];
    const qty = Number(v('pk-conf')) || 0;
    if (!t || qty <= 0) { toast('Cantidad inválida', 'warn'); return; }

    // El escaneo de SKU/ubicación se valida en RPC si se suministra.
    const { data, error } = await db.rpc('rf_pick', {
      p_task_id: taskId,
      p_qty: qty,
      p_usuario: sesion?.nombre || null,
      p_scan_sku: t.sku,
      p_scan_ubicacion: t.ubicacion || null
    });
    if (rpcError(error)) return;

    toast(`${t.sku} · ${qty} uds ✓`, 'ok');
    await loadPedidosParaPicking();
    el('pick-pedido').value = '';
    el('pick-task-wrap').style.display = 'none';
    await refreshHomeKPIs();
  };

  // Recepción: busca primero la línea del pedido, no el stock global.
  window.buscarSkuEntrada = async function buscarSkuEntradaV3(sku) {
    if (!sku || sku.length < 2 || !entPedidoId || !db) return;
    const { data: lineas, error } = await db.from('pe_lineas')
      .select('id,sku,descripcion,cantidad_ped,cantidad_rec,lote,vencimiento,estado')
      .eq('pedido_id', entPedidoId)
      .ilike('sku', `%${sku}%`)
      .limit(5);
    if (rpcError(error)) return;

    const l = (lineas || []).find(x => Number(x.cantidad_ped || 0) > Number(x.cantidad_rec || 0));
    const wrap = el('ent-sku-result');
    if (!l) {
      wrap.style.display = 'block'; wrap.className = 'scan-result err';
      el('ent-sku-desc').textContent = 'SKU no pertenece al pedido o ya está completo';
      el('ent-sku-info').textContent = sku;
      entSkuActual = null;
      return;
    }

    entSkuActual = l;
    const restante = Math.max(0, Number(l.cantidad_ped || 0) - Number(l.cantidad_rec || 0));
    wrap.style.display = 'block'; wrap.className = 'scan-result';
    el('ent-sku-desc').textContent = l.descripcion || l.sku;
    el('ent-sku-info').textContent = `Pendiente: ${restante} · SKU: ${l.sku}`;
    el('ent-qty').value = Math.min(1, restante) || 0;
  };

  window.confirmarEntrada = async function confirmarEntradaV3() {
    if (!entSkuActual || !entPedidoId) { toast('Selecciona un pedido y SKU válido', 'warn'); return; }
    const qty = Number(v('ent-qty')) || 0;
    if (qty <= 0) { toast('La cantidad debe ser mayor a 0', 'warn'); return; }
    if (!db || !wh_codigo) { toast('Sin conexión o sin almacén', 'err'); return; }

    const { data, error } = await db.rpc('rf_receive', {
      p_pedido_id: entPedidoId,
      p_sku: entSkuActual.sku,
      p_qty: qty,
      p_wh_id: wh_codigo,
      p_ubicacion: v('ent-ubic') || null,
      p_lote: v('ent-lote') || null,
      p_vencimiento: v('ent-vence') || null,
      p_usuario: sesion?.nombre || null
    });
    if (rpcError(error)) return;

    entLineasConf.push({ sku: entSkuActual.sku, qty, ubic: v('ent-ubic') || null, lote: v('ent-lote') || null });
    renderLineasConfirmadas();
    toast(`${entSkuActual.sku} · ${qty} uds recibidas ✓`, 'ok');
    el('ent-sku-manual').value = '';
    el('ent-qty').value = 1;
    el('ent-lote').value = '';
    el('ent-vence').value = '';
    el('ent-ubic').value = '';
    el('ent-sku-result').style.display = 'none';
    entSkuActual = null;
    await loadPedidoEntrada();
    await refreshHomeKPIs();
  };

  window.confirmarReubicacion = async function confirmarReubicacionV3() {
    if (!reubSkuActual) { toast('Escanea el artículo primero', 'warn'); return; }
    const qty = Number(v('reub-qty')) || 0;
    const ori = v('reub-ori').trim();
    const dest = v('reub-dest').trim();
    if (qty <= 0 || !ori || !dest) { toast('Completa cantidad, origen y destino', 'warn'); return; }
    if (ori === dest) { toast('Origen y destino no pueden ser iguales', 'warn'); return; }

    const { error } = await db.rpc('rf_relocate', {
      p_sku: reubSkuActual.sku,
      p_wh_id: wh_codigo,
      p_qty: qty,
      p_origen: ori,
      p_destino: dest,
      p_usuario: sesion?.nombre || null,
      p_motivo: v('reub-motivo') || null
    });
    if (rpcError(error)) return;
    toast(`${reubSkuActual.sku}: ${ori} → ${dest} ✓`, 'ok');
    resetReubicacion();
  };

  window.confirmarAjuste = async function confirmarAjusteV3() {
    const stk = window._ajStkActual;
    if (!stk) { toast('Busca un artículo primero', 'warn'); return; }
    const qty = Number(v('aj-qty')) || 0;
    const tipo = v('aj-tipo');
    const wh = v('aj-wh') || wh_codigo;
    if (qty < 0 || (qty === 0 && tipo !== 'CORRECCION')) { toast('Cantidad inválida', 'warn'); return; }

    const { error } = await db.rpc('rf_adjust', {
      p_stock_id: stk.id,
      p_tipo: tipo,
      p_qty: qty,
      p_wh_id: wh,
      p_usuario: sesion?.nombre || null,
      p_motivo: v('aj-motivo') || 'Ajuste RF'
    });
    if (rpcError(error)) return;
    toast(`${stk.sku} ajustado ✓`, 'ok');
    resetAjuste();
    refreshHomeKPIs();
  };

  // Realtime sin duplicar canales: un canal único para la sesión.
  window.subscribeRealtime = function subscribeRealtimeV3() {
    if (!db) return;
    if (window.__rfRealtime) {
      try { db.removeChannel(window.__rfRealtime); } catch (_) {}
    }
    const channel = db.channel('m-intel-rf-live');
    ['pedidos_entrada','pedidos_salida','carros_entrada','rf_tasks','stock','movimientos'].forEach(tabla => {
      channel.on('postgres_changes', { event: '*', schema: 'public', table: tabla }, () => {
        refreshHomeKPIs();
        if (tabla === 'rf_tasks') loadPedidosParaPicking();
        if (tabla === 'pedidos_entrada') loadPedidosEntrada();
        if (tabla === 'carros_entrada') loadCarrosRF();
      });
    });
    channel.subscribe();
    window.__rfRealtime = channel;
  };

  // Evita múltiples streams de cámara activos al navegar.
  const originalGoScreen = window.goScreen;
  window.goScreen = function goScreenV3(id) {
    if (typeof originalGoScreen === 'function') originalGoScreen(id);
    Object.entries(scanners || {}).forEach(([videoId, interval]) => {
      const video = el(videoId);
      if (video && !video.closest('.screen')?.classList.contains('active')) {
        clearInterval(interval);
        if (video.srcObject) video.srcObject.getTracks().forEach(t => t.stop());
        delete scanners[videoId];
      }
    });
  };

  wait(() => {
    // Sustituye el texto del botón para hacer explícito que no hay contraseña demo.
    const b = document.querySelector('#login-screen .btn-primary');
    if (b) b.textContent = '✓ Entrar como operador';
    const pass = el('login-pass');
    if (pass) {
      pass.style.display = 'none';
      pass.previousElementSibling && (pass.previousElementSibling.style.display = 'none');
    }
  });
})();
