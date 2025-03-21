import secrets
import string
import bcrypt

# Función para generar una contraseña aleatoria segura
def generate_password(length=12):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

# Usuario de Prometheus
username = "admin"
password = generate_password()

# Hashear la contraseña
hashed_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())

# Guardar en formato YAML para Prometheus
config = f"{username}: {hashed_password.decode()}"

# Guardar en un archivo YAML
with open("basic_auth_users.yml", "w") as file:
    file.write(config)

print("Usuario:", username)
print("Contraseña:", password)
print("Hash guardado en basic_auth_users.yml")
