docker exec -it odoo19-web-1 bash -c "
odoo --no-http --workers=0 --max-cron-threads=0 \
--load=base,web \
--db_host=odoo19-db-1 \
--db_user=odoo \
--db_password=odoo \
--stop-after-init \
--log-level=info \
-u all \
-d nombrebasededatos
"
