# Lectura fantasma 
  
```
Begin tran t1  
  insert ... emp(10,Luis)  
CKP  
update  -> error  
```  
aqui se hace otra begin tran t2  
```
update emp where cue=10  
```  
y depues se hace el commit de la t1  
```
commit  
```
El manejador hace un UNDO, porque puede generar un error debido a esa transacion fantasma  

# Leer lecturas fantasmas
```
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
```
Esta es la más rapida porque no realiza validaciones. SOLO se debe usar cuando se esta seguro que ya no habra modificaciones en la BD

