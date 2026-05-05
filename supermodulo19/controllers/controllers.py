# from odoo import http


# class Supermodulo19(http.Controller):
#     @http.route('/supermodulo19/supermodulo19', auth='public')
#     def index(self, **kw):
#         return "Hello, world"

#     @http.route('/supermodulo19/supermodulo19/objects', auth='public')
#     def list(self, **kw):
#         return http.request.render('supermodulo19.listing', {
#             'root': '/supermodulo19/supermodulo19',
#             'objects': http.request.env['supermodulo19.supermodulo19'].search([]),
#         })

#     @http.route('/supermodulo19/supermodulo19/objects/<model("supermodulo19.supermodulo19"):obj>', auth='public')
#     def object(self, obj, **kw):
#         return http.request.render('supermodulo19.object', {
#             'object': obj
#         })

