1: en local invocamos el script ./graber_cloud y lanzara peticiones hacia el simple worker que actua de servidor. luego los workers previamente configurados iran cogiendo de ahi las peticiones y procesandolas

2: fichero.py -> una vez se hallan generado las url y esten guardadas en elastic search se cogen de ahi con un scroll y se añaden en lotes de 50 url para procesar su contenido y extraer los items de rss para insertarlos en un nuevo indice.
