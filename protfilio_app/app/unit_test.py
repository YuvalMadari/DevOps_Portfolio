import unittest
import sys

# Mock config before importing app
import types
test_config = types.ModuleType('config')
test_config.SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
test_config.SQLALCHEMY_TRACK_MODIFICATIONS = False
test_config.TESTING = True
test_config.SECRET_KEY = 'test-key'
sys.modules['config'] = test_config

from app import app, db, Tool

class SuperSimpleTest(unittest.TestCase):
    
    def setUp(self):
        """Set up for each test"""
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        self.client = app.test_client()
        
        with app.app_context():
            db.create_all()
    
    def tearDown(self):
        """Clean up after each test"""
        with app.app_context():
            db.drop_all()
    
    def test_health_works(self):
        """Test health endpoint returns 200"""
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
    
    def test_home_works(self):
        """Test home page returns 200"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
    
    def test_can_add_tool(self):
        """Test can add a tool"""
        response = self.client.post('/tools', data={
            'name': 'hammer',
            'definition': 'hits things'
        })
        self.assertEqual(response.status_code, 200)
        
        # Check if tool exists in database
        with app.app_context():
            tool = Tool.query.filter_by(name='hammer').first()
            self.assertIsNotNone(tool)
    
    def test_can_get_tool(self):
        """Test can get a tool"""
        # Add tool first
        with app.app_context():
            tool = Tool(name='saw', definition='cuts things')
            db.session.add(tool)
            db.session.commit()
        
        # Get tool
        response = self.client.get('/tool/saw')
        self.assertEqual(response.status_code, 200)
    
    def test_can_delete_tool(self):
        """Test can delete a tool"""
        # Add tool first
        with app.app_context():
            tool = Tool(name='drill', definition='makes holes')
            db.session.add(tool)
            db.session.commit()
        
        # Delete tool
        response = self.client.delete('/tool/drill')
        self.assertEqual(response.status_code, 200)
        
        # Check tool is gone
        with app.app_context():
            tool = Tool.query.filter_by(name='drill').first()
            self.assertIsNone(tool)

if __name__ == '__main__':
    # Run with minimal output
    unittest.main(verbosity=1)