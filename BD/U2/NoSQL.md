# NoSQL

Busca la **disponibilidad** sacrificando la **concistencia**  

- Relacional -> tabla_llave_primaria_etc  

			Modelo conceptual -> -v

NoSQL:				<- Modelos lógicos  
-MongoDB: Documento  
-Neo4J: Grafos  
-Cassandra: Key-value    

Cada manejador tiene su estructura de almacenamiento    

## *MONGO*  
Ejemplo  
  
{  
  "Name": "ABC",  
  "Phone": ["6671234567", "6677654321"],  
  "City": "Culiacán"  
}    

Libre de esquemas (schema-less)  
-No se requiere una estructura fija o predefinida    

JSON  
"_id" 1,
"name":{"first": "John", "last": "Doe"} 	<- Documento dentro de documento    

### **Embebido y referencial**  
Embebido: BD dentro de BD  
Referencia: Hace referencia a una tabla  
