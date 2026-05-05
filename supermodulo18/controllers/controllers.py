# -*- coding: utf-8 -*-
# from odoo import http


# class Supermodulo18(http.Controller):
#     @http.route('/supermodulo18/supermodulo18', auth='public')
#     def index(self, **kw):
#         return "Hello, world"

#     @http.route('/supermodulo18/supermodulo18/objects', auth='public')
#     def list(self, **kw):
#         return http.request.render('supermodulo18.listing', {
#             'root': '/supermodulo18/supermodulo18',
#             'objects': http.request.env['supermodulo18.supermodulo18'].search([]),
#         })

#     @http.route('/supermodulo18/supermodulo18/objects/<model("supermodulo18.supermodulo18"):obj>', auth='public')
#     def object(self, obj, **kw):
#         return http.request.render('supermodulo18.object', {
#             'object': obj
#         })

