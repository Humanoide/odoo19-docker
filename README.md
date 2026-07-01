# odoo19-docker
##Se deben seguir estos pasos para instalar odoo19, nginx proxy manager, portainer y webmin.
Muchos ficheros se conservan por compatibilidad pero actualmente no tienen uso
Descargarse la carpeta odoo19-docker en el servidor donde se vaya a hacer la instalación
Dar permiso de ejecución a todo el contenido de la carpeta

Ejecutar script

./instala-odoo19.sh

Pedirá que  ingreses en portainer y cambies la contraseña. Tambien deberas listar el log de portainer para poder obtener el token de segurdiad. En el environement debes poner la ip de la máquina.

Cuando hayas terminado selecciona si para continuar

Ejecutar script

./crea_base_datos.sh

Se creará una base de datos con el nombre "plantilla". Podrás duplicarla con el nombre que quieras

Ejecutar script

./crea_proxy_npm.sh

Preguntará el nombre del proyecto y creará los próxys inversos.
