# Respaldos  
## Respaldo FULL
"""
BACKUP DATABASE basededatos_nombre  
TO DISK = 'C:data\basededatos_nombre-full.bak';    
"""
  
## Respaldo DIFFERENTIAL
´´´
BACKUP DATABASE basededatos_nombre  
TO DISK = 'C:\data\basededatos_nombre-dif.bak'  
WITH DIFFERENTIAL;    
´´´
  
``## Respaldo TRANSACCIONAL
BACKUP LOG basededatos_nombre  
TO DISK = 'C:\data\basededatos_nombre-log.bak';``

