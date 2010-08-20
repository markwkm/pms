from pms.tests import *

class TestSourcesController(TestController):

    def test_index(self):
        response = self.app.get(url('sources'))
        # Test response...

    def test_index_as_xml(self):
        response = self.app.get(url('formatted_sources', format='xml'))

    def test_create(self):
        response = self.app.post(url('sources'))

    def test_new(self):
        response = self.app.get(url('new_source'))

    def test_new_as_xml(self):
        response = self.app.get(url('formatted_new_source', format='xml'))

    def test_update(self):
        response = self.app.put(url('source', id=1))

    def test_update_browser_fakeout(self):
        response = self.app.post(url('source', id=1), params=dict(_method='put'))

    def test_delete(self):
        response = self.app.delete(url('source', id=1))

    def test_delete_browser_fakeout(self):
        response = self.app.post(url('source', id=1), params=dict(_method='delete'))

    def test_show(self):
        response = self.app.get(url('source', id=1))

    def test_show_as_xml(self):
        response = self.app.get(url('formatted_source', id=1, format='xml'))

    def test_edit(self):
        response = self.app.get(url('edit_source', id=1))

    def test_edit_as_xml(self):
        response = self.app.get(url('formatted_edit_source', id=1, format='xml'))
