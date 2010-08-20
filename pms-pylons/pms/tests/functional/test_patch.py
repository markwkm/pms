from pms.tests import *

class TestPatchController(TestController):

    def test_index(self):
        response = self.app.get(url(controller='patch', action='index'))
        # Test response...
