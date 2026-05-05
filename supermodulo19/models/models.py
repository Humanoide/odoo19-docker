# from odoo import models, fields, api


# class supermodulo19(models.Model):
#     _name = 'supermodulo19.supermodulo19'
#     _description = 'supermodulo19.supermodulo19'

#     name = fields.Char()
#     value = fields.Integer()
#     value2 = fields.Float(compute="_value_pc", store=True)
#     description = fields.Text()
#
#     @api.depends('value')
#     def _value_pc(self):
#         for record in self:
#             record.value2 = float(record.value) / 100

