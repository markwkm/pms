from django.db import models

class Patch(models.Model):
	diff = models.TextField()
	name = models.CharField(maxlength=1000)

	class Admin:
		pass
