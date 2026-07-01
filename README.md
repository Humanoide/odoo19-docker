# odoo19-docker
## Se deben seguir estos pasos para instalar odoo19, nginx proxy manager, portainer y webmin.
Muchos ficheros se conservan por compatibilidad pero actualmente no tienen uso. 
Hay que descargar la carpeta escargarse la carpeta https://github.com/Humanoide/odoo19-docker/ en el servidor donde se vaya a hacer la instalación
git clone https://github.com/Humanoide/odoo19-docker/

Dar permiso de ejecución a todo el contenido de la carpeta

### Ejecutar script de instalación de odoo

`./instala-odoo19.sh`

Pedirá que  ingreses en portainer y cambies la contraseña. Tambien deberas listar el log de portainer para poder obtener el token de segurdiad. En el environement debes poner la ip de la máquina.

Cuando hayas terminado selecciona si para continuar

## Ejecutar script de creación de la base de datos de odoo

`./crea_base_datos.sh`

Se creará una base de datos con el nombre "plantilla". Podrás duplicarla con el nombre que quieras

## Ejecutar script de creación de proxys inversos

`./crea_proxy_npm.sh`

Preguntará el nombre del proyecto y creará los próxys inversos.
