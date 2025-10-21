# Transacciones
Para hacer un DELETE de una TUPLA que CONVINA 2 o más tablas  
la transaccion de DELETE debe ser GRUPAL, es decir, se deben  
hacer las 2 a las. Se quiere que ambas transacciones salgan BIEN,  
no que si 1 sale MAL la otra pueda salir BIEN.

## Transaccion IMPLICITA
DELETE USUARIOS...  
DELETE ADULTOS_Usuarios...  
- Aqui si una falla la otra no le afecta
- Esto deja basura si una falla y la otra se completa

## Transaccion EXPLICITA
BEGIN TRAN  
  DELETE USUARIOS...  
  DELETE ADULTOS_Usuarios...  
COMMIT TRAN  
- Aqui ambas transacciones implicitas se hacen a la par.
- Si una falla, la otra tambien.
- Para que AMBAS SE COMPLETEN, ambas deben salir bien.
  
---
---
  
## @@TRANCOUNT
Cuenta las transacciones activas existen.  
  
Begin tran           ->      @@trancount = 1
  Insert..
  
  Begin tran        ->       @@trancount = 2
    Delete
    Update
  Commit tran       ->       @@trancount = 1
  
  Delete
Commit tran        ->       @@trancount = 0
