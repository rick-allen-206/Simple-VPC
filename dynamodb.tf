# resource "aws_dynamodb_table_item" "this" {
#   provider = aws.network

#   table_name = "vpc-metadata-table"
#   hash_key   = "id"

#   item = jsonencode(
#     {
#       "id": {
#         "S": "logical-mammoth-5MN0hQ"
#       },
#       "attributes": {
#         "M": {
#           "metadata": {
#             "M": {
#               "database": {
#                 "M": {
#                   "rtb-12345678": {
#                     "M": {}
#                   }
#                 }
#               },
#               "gwlbe": {
#                 "M": {
#                   "rtb-12345678": {
#                     "M": {}
#                   }
#                 }
#               },
#               "private": {
#                 "M": {
#                   "rtb-12345678": {
#                     "M": {}
#                   }
#                 }
#               },
#               "public": {
#                 "M": {
#                   "rtb-12345678": {
#                     "M": {}
#                   }
#                 }
#               },
#               "tgw": {
#                 "M": {
#                   "rtb-12345678": {
#                     "M": {}
#                   }
#                 }
#               }
#             }
#           },
#           "tgw_attachment_id": {
#             "S": "test"
#           }
#         }
#       },
#       "env": {
#         "S": "nonprd"
#       },
#       "name": {
#         "S": "logical-mammoth-5MN0hQ"
#       }
#     }
#   )
# }