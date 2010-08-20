from pms.tests import *

class TestDeveloperController(TestController):

    def test_index(self):
        response = self.app.get(url(controller='developer', action='index'))
        # Test response...
