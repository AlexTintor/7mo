# Create DataBase
    ->   ejemplo.mdf  
    ->  ejemplo.ldf (archivo de transacciones LOG)  

## Validaciones
```asda
Begin tran
  insert into loan
  if error..
    rollback tran
    return
  end

  update copy
  if .. error
    rollback tran
    RETURN
  END
```

## Atomicidad
Se realicen todas las instrucciones de la transaccion
- Commit

## Percistencia
Cambios se guardan en el Disco Duro
- Update
- Insert
- CKP

### Es inconsistente cuando:
Solo es o Atomica o Persistente


