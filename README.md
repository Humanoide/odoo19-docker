# odoo19-docker
## Se deben seguir estos pasos para instalar odoo19, nginx proxy manager, portainer y webmin.
Muchos ficheros se conservan por compatibilidad pero actualmente no tienen uso. 
Hay que descargar la carpeta https://github.com/Humanoide/odoo19-docker/ en el servidor donde se vaya a hacer la instalación

`git clone https://github.com/Humanoide/odoo19-docker.git`

Dar permiso de ejecución a todo el contenido de la carpeta

`chmod +x *`

## Ejecutar script de hoja de claves
Para crear una hoja con las cinco contraseñas ejecuta el script hoja_claves.sh

`hoja_claves.sh`

En algún caso empezamos a trabajar con contraseñas poco seguras. Posteriormente las sustituimos por estas.


## Ejecutar script de instalación de odoo

`./instala-odoo19.sh`

Pedirá que  ingreses en portainer , crees la contraseña. Tambien deberas listar el log de portainer para poder obtener el token de seguridad. Para ello ejecuta el script

`docker logs -f portainer`

En el environement debes poner la ip de la máquina.

Cuando hayas terminado selecciona si para continuar

## Ejecutar script de creación de la base de datos de odoo

`./crea_base_datos.sh`

Se creará una base de datos con el nombre "plantilla". Podrás duplicarla con el nombre que quieras

## Ejecutar script de instalación de módulos OCA

`./instala_modulos_plantilla.sh`

## Ejecutar script de creación de proxys inversos
Ponemos usuario y contraseña en nginx proxy manager

Ejecutamos el script

`./crea_proxy_npm.sh`

Preguntará el nombre del proyecto y creará los próxys inversos.

## Nos logueamos en odoo
Ejecutamos el asistente de configuracion y creamos los topónimos españoles y los bancos españoles

Después arreglamos los diarios de ventas y compras para que las facturas sean FV y FC

Cambiamos la contraseña de admin y ponemos la de la hoja de claves

