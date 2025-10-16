# Respaldos  

## Respaldo Completo (Full Backup):  
Respaldo para restaurar la base de datos a antes de una trajedia.  
- Click derecho sobre la BD > Task > BackUps > ...

Para recuperarla:  
- Click derecho sobre DATABASES (carpeta) > Restore DB > ...

## Respaldo diferencial  
Respalda la informacion nueva despues del ultimo pool.
- Respaldo Full > (se elimina el respaldo anterior de las opciones) Luego se hace respaldo diferencial.
Listo, asi las veces que sea necesario.  

## Respaldo trancaccional 
- Mejor para hacerlo cada poco tiempo y asi no perder info
- Más rapido que el "Diferencial"


# Mejor forma de usarlos:  
10:00 am - Respaldo full (tarda tiempo)  
10:05 am - Respaldo Transaccional (toma muy poco timepo)[Solo toma los datos: > 10:00 && <= 10:05]  
10:10 am - Respaldo Transaccional " , [ > 10:05 && <= 10:10 ]  
...  
10:30 am - Respaldo Diferencial (Toma más tiempo que el Transaccional y menos que el full) [Toma los datos desde el ultimo pool, osea desde el ultimo full o ultimo Diferencial] [ > 10:00 && <= 10:30 ]
