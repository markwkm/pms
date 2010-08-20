from formencode import Schema
from formencode.validators import Email, FieldsMatch, \
                                  FieldStorageUploadConverter, Int, \
                                  PlainText, String

class PatchForm(Schema):
    allow_extra_fields = True
    filter_extra_fields = True
    applies_name = PlainText(not_empty=True)
    name = String(not_empty=True)
    applies_name = String(not_empty=True)
    diff = FieldStorageUploadConverter(not_empty=True)
    strip_level = Int(not_empty=True)
    software_id = Int(not_empty=True)

class SignupForm(Schema):

    allow_extra_fields = True
    filter_extra_fields = True
    email = Email(not_empty=True)
    login = PlainText(not_empty=True)
    first = PlainText(not_empty=True)
    last = PlainText(not_empty=True)
    password1 = String(min=8, not_empty=True)
    password2 = String(min=8, not_empty=True)
    chained_validators = [FieldsMatch('password1', 'password2')]
