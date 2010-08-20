from pms.tests import *

class TestFilterRequestController(TestController):

    def test_index(self):
        response = self.app.get(url(controller='filter_request', action='index'))
        # Test response...
