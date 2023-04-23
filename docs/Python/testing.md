## Pytest

### Testing endpoints

```py
class TestClsNamePage:
	def setup_method(self):
		self.app = app.test_client()
		self.app_context = app.app_context()
		self.app_context.push()

	# Test get endpoint and assert content on page
	def test_get_endpoint(self):
		response = self.app.get("/")
		assert response.status_code == 200

		page_content = response.data.decode("utf-8")
		assert "Hello!" in page_content

	# Test endpoint with headers
	def test_endponint_with_headers(self):
		response = self.app.get("/", headers={"Auth-Token": "some-random-auth-token-values"})
		assert response.status_code == 200

	# Test get endpoint and content on page after redirect
	def test_get_endpoint(self):
		response = self.app.get("/redirect_to_another_page", follow_redirects=True)
		assert response.status_code == 200

		page_content = response.data.decode("utf-8")
		assert "Redirected" in page_content

	# Test get endpoint with JSON response
	def test_get_endpoint(self):
		# assuming endpoint return {"message": "Hello!"}
		response = self.app.get("/json_response")
		assert response.status_code == 200

		data = json.loads(response.data)
		assert data["message"] == "Hello!"

	# Test post endpoint - HTML form submission
	def test_post_form_submit(self):
		response = self.app.post("/users", data={"name": "user", "email": "user@test.com"})
		assert response.status_code == 200

	# Test post endpoint - HTML form submission with multi select
	def test_post_multi_select_form_submit(self):
		# Remember to import ImmutableMultiDict: `from werkzeug.datastructures import ImmutableMultiDict`
		form = ImmutableMultiDict(
			[("user_id", "user_id_1"), ("user_id", "user_id_2"), ("user_id", "user_id_2")]
		)
		response = self.app.post("/users/multi_select", data=form)
		assert response.status_code == 200

	# Test post endpoint JSON params
	def test_post_json_params(self):
		response = self.app.post("/users", json={"name": "user", "email": "user@test.com"})
		assert response.status_code == 200
```

### Parametrize tests

```py
import pytest

class TestClsName:
	@pytest.mark.parametrize("param_1, param_2, param3, expected_result", [
		(test_1_param_1, test_1_param_2, test_1_param_3, test_1_expected_result),
		(test_2_param_1, test_2_param_2, test_2_param_3, test_2_expected_result),
		(test_3_param_1, test_3_param_2, test_3_param_3, test_3_expected_result),
	])
	def test_some_test_with_parametrize(self, param_1, param_2, param3, expected_result):
		result = method_to_test(param_1, param_2, param3)
		assert result == expected_result
```

### Mock/patching

** Mock method to return specific value **

```py
class TestClsName:
	def test_method_with_patch(self):
		with patch("path.to.class.ClassName.method_name") as mocked_method:
			mocked_method.return_value = [1,2,3]
```

** Mock method to raise exception **

```py
class TestClsName:
	def test_method_with_mocked_exception(self):
		with patch("path.to.class.ClassName.method_name") as mocked_method:
			mocked_method.side_effect = Exception("error")
```

** Mock response with JSON response, status_code **

```py
class MockResponse:
	def __init__(self, json_data, status_code):
		self.json_data = json_data
		self.status_code = status_code

	def json(self):
		return self.json_data

class TestClsName:
	def test_method_with_post_request(self):
		with patch("app.model.ClsName.requests.post") as mocked_request:
			mocked_request.return_value=MockResponse({"message": "ta-da", "status": "success"}, 200)
			result = method_with_post_request()
			...

```

** Mock response with raise_for_status **

```py
class TestClsName:
	def test_method_with_post_request_raise_for_status(self):
		with patch("app.model.ClsName.requests.post") as mocked_request:
			mocked_status = Mock(status_code=500)
			mocked_status.raise_for_status = Mock(side_effect=requests.exceptions.RequestException("Error"))
			mocked_request.return_value = mocked_status
			result = method_with_post_request()
			...

```

### Mock AWS services with moto

For example, creating a S3 mock with [moto](https://github.com/getmoto/moto)

```py
@pytest.fixture(scope="session")
def aws_credentials():
	"""Mocked AWS Credentials for moto."""
	os.environ["AWS_ACCESS_KEY_ID"] = "testing"
	os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
	os.environ["AWS_SECURITY_TOKEN"] = "testing"
	os.environ["AWS_SESSION_TOKEN"] = "testing"
	os.environ["AWS_DEFAULT_REGION"] = "eu-west-1"


@pytest.fixture(autouse=False)
def s3_client(aws_credentials):
	with mock_s3():
		conn = boto3.client("s3", region_name="us-east-1")
		yield conn
```

And in tests, use `s3_client` as fixture

```py
@pytest.fixture
def s3_bucket(s3_client):
	s3_client.create_bucket(Bucket=bucket_name)
	yield

class TestS3Service:
	def test_s3_bucket_list_objects(self, s3_client, s3_bucket):
		S3Service().list_objects()
		...

```

### Monkeypatching SQLAlchemy connection

** For SQLAlchemy 1.4 **

```py
@pytest.fixture
def app(request):
	app = _app
	with app.app_context():
		yield app

@pytest.fixture
def db(app, request, monkeypatch):
	connection = _db.engine.connect()
	transaction = connection.begin()

	# https://github.com/pallets/flask-sqlalchemy/pull/249#issuecomment-628303481
	monkeypatch.setattr(_db, "get_engine", lambda *args, **kwargs: connection)

	try:
		yield _db
	finally:
		_db.session.remove()
		transaction.rollback()
		connection.close()
```

And use `db` as fixture

```py
@pytest.mark.usefixtures("db")
class TestClsName:
	...

```

```py
def test_method_name(self, db):
	...
```

When testing database rollback use `db.session.begin_nested()` to begin a "nested" transaction/savepoint

```py
class TestClsName:
	def test_method_with_db_rollback(self, db):
		create_test_objects()
		db.session.begin_nested()
		result = method_with_db_rollback()
		assert result == expected_result
```

### Assert exception raised

```py
class TestUser:
	def test_user_init_failed_on_missing_required_values(self):
		with pytest.raises(TypeError) as error:
			User()
		assert str(error.value) == "__init__() missing 2 required positional argument: 'name', 'email'"
```

### Assert parameters pass to method/mock method

Passing the actual method to `side_effect` will call the actual method instead of "mocked"

```py
	with patch.object(ClsName, "method_name", side_effect=ClsName().method_name) as mocked_method:
		mocked_method.assert_called_with(
			param_1=expected_param_1,
			param_2=expected_param_2,
			param_3=expected_param_3,
		)
```

### Mock results of repeated/multiple calls to the same method

For example, calling a method in a loop:

```py
def loopy_loop():
	for i in range(3):
		result = do_something()
		print(result)

```

To mock the results of repeated `do_something` calls

```py
	with patch("path.to.do_something", side_effect=(4, 5, 6)):
		loopy_loop()
```
