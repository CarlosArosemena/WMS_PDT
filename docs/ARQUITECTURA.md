# Arquitectura RF

```text
Android APK / WebView Capacitor
        |
        v
Supabase JS client
        |
        +---- consultas de lectura
        |
        +---- RPC transaccional
                    |
                    +-- pe_lineas / pedidos_entrada
                    +-- ps_lineas / pedidos_salida
                    +-- rf_tasks
                    +-- stock
                    +-- ubicaciones
                    +-- movimientos
                    +-- operadores
```

La APK no debe actualizar varias tablas críticas con llamadas independientes cuando una operación de almacén requiere consistencia. Para eso se usan funciones PostgreSQL transaccionales.

## Flujo de picking

1. El WMS web genera `rf_tasks`.
2. La APK toma una tarea pendiente asignada al operador/almacén.
3. El operador escanea SKU y ubicación.
4. La APK valida cantidad.
5. RPC bloquea la tarea y el stock.
6. Se actualiza `rf_tasks`, `ps_lineas`, `stock`, `pedidos_salida` y `movimientos` dentro de una transacción.

## Flujo de recepción

1. APK selecciona pedido liberado.
2. Se identifica `pe_lineas` por pedido + SKU.
3. Se calcula saldo pendiente.
4. RPC bloquea la línea y stock.
5. Se registra recepción, stock y movimiento.
6. El estado del pedido se recalcula.
