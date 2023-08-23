## IntEnum

Storing the enum integer value to the database

```py
from sqlalchemy import types

class IntEnum(types.TypeDecorator):
	impl = Integer

	def __init__(self, enumtype, *args, **kwargs):
		super().__init__(*args, **kwargs)
		self._enumtype = enumtype

	def process_bind_param(self, value, dialect):
		return value.value

	def process_result_value(self, value, dialect):
		return self._enumtype(value)
```

```py
class Role(enum.Enum):
	REGISTERED = 1
	MODERATOR = 2
	ADMIN = 3


class User(db.Model):
	__tablename__ = "users"

	id: uuid.UUID = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
	name: str = db.Column(db.String(50), nullable=False)
	email: str = db.Column(db.String(50), nullable=False)
	role: int = db.Column(IntEnum(Role), nullable=False, default=1)

```

### Query mixin

```py
class QueryMixin:
	@classmethod
	def get(cls, id):
		return cls.query.get(id)

	@classmethod
	def _filters(cls, kwargs):
		return [getattr(cls, attr) == kwargs[attr] for attr in kwargs]

	@classmethod
	def find_by(cls, **kwargs):
		filters = cls._filters(kwargs)
		return db.session.execute(db.select(cls).where(*filters)).scalars().first()

	@classmethod
	def find_all(cls, **kwargs):
		filters = cls._filters(kwargs)
		return db.session.execute(db.select(cls).where(*filters)).scalars().all()

	@classmethod
	def find_all_in(cls, **kwargs):
		filters = [getattr(cls, attr).in_(kwargs[attr]) for attr in kwargs]
		return db.session.execute(db.select(cls).where(*filters)).scalars().all()

	@classmethod
	def find_all_not_in(cls, **kwargs):
		filters = [getattr(cls, attr).not_in(kwargs[attr]) for attr in kwargs]
		return db.session.execute(db.select(cls).where(*filters)).scalars().all()

	@classmethod
	def delete_if_exists(cls, **kwargs):
		filters = cls._filters(kwargs)
		cls.query.where(*filters).delete()
		db.session.commit()

	def delete(self):
		db.session.delete(self)
		db.session.commit()

	def to_dict(self):
		return {
			column.name: getattr(self, column.name)
			if not isinstance(getattr(self, column.name), (datetime, date))
			else getattr(self, column.name).isoformat()
			for column in self.__table__.columns
		}
```

### Insert...returning

```py
	data = [
		{"name": "Sally", "email": "sally@user.email"},
		{"name": "Jon", "email": "jon@user.email"},
		{"name": "Ken", "email": "ken@user.email"},
		{"name": "Jess", "email": "jess@user.email"}
	]
	employees = db.session.execute(insert(Employee).returning(Employee), data).all()
```

### Update...returning

```py
	employee_id = "ec38f27b-79a2-4739-b96a-6bc2babcc2c9"
	update_params = {"name": "Ken", "email": "ken@another.email"}
	update_stmt = update(Employee).where(Employee.id == employee_id).values(update_params).returning(Employee)
	employees = db.session.execute(update_stmt).first()
```

### Update multiple records where the `WHERE` conditons is different for each record

```py
	data = [
		{"employee_id": "443bd75a-3baa-4b17-a391-af00af9e3325", "name": "Sally", "email": "sally@user.email", "new_department": "Marketing"},
		{"employee_id": "52ca61aa-399d-4a0c-9482-6e0ec3ab4891", "name": "Jon", "email": "jon@user.email", "new_department": "IT"},
		{"employee_id": "ec38f27b-79a2-4739-b96a-6bc2babcc2c9", "name": "Ken", "email": "ken@user.email", "new_department": "Finance"},
		{"employee_id": "0d28cbbd-f073-4420-9f73-3dfc93c7696e", "name": "Jess", "email": "jess@user.email", "new_department": "Marketing"},
	]

	update_stmt = (
		update(Employee)
		.where(Employee.id == bindparam("employee_id"))
		.values(
			{"department_id": select(Department.id).where(Department.name == bindparam("new_department")).scalar_subquery()}
		)
	)
	db.session.execute(update_stmt, data)
```

### Nested transaction

```py
	db.session.begin_nested()
```
