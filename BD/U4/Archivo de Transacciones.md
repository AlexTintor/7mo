# Create DataBase
    ->   ejemplo.mdf  
    ->  ejemplo.ldf (archivo de transacciones LOG)  

## Validaciones
'''asda
Begin tran
  insert into loan
  if error..
    rollback tran
    return
  end

  update copy
  if .. error
    rollback tran
'''

## Atomicidad
Se realicen todas las instrucciones de la transaccion

## Percistencia
Cambios se guardan en el Disco Duro

