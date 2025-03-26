## `Hash.py` Script Description

This Python script generates a secure random password, hashes it using bcrypt, and saves it to a YAML file for use with Prometheus Basic Authentication.

### Detailed Description

1.  **Module Imports:**
    * `secrets`: Used for generating cryptographically secure random passwords.
    * `string`: Used to define the character alphabet for the password.
    * `bcrypt`: Used for hashing the password.

2.  **`generate_password(length=12)` Function:**
    * Generates a random password of the specified length (default 12 characters).
    * Uses `secrets.choice` to select random characters from the alphabet (letters and digits).
    * Returns the generated password as a string.

3.  **Username and Password Generation:**
    * Defines the username as "admin".
    * Calls the `generate_password()` function to generate a random password.

4.  **Password Hashing:**
    * Uses `bcrypt.hashpw()` to hash the password.
    * The password is encoded to bytes using `password.encode("utf-8")`.
    * `bcrypt.gensalt()` is used to generate a random salt.

5.  **YAML Format for Prometheus:**
    * Formats the username and hashed password into a YAML string.
    * The hashed password is decoded to a string using `hashed_password.decode()`.

6.  **Saving to YAML File:**
    * Opens the file `basic_auth_users.yml` in write mode.
    * Writes the formatted YAML string to the file.

7.  **Information Output:**
    * Prints the username.
    * Prints the generated password (for initial reference; it should not be stored this way in a production environment).
    * Prints a message indicating that the hash has been saved to `basic_auth_users.yml`.

### Purpose

The main purpose of this script is to generate a secure password and its hash for configuring basic authentication in Prometheus, storing the configuration in a YAML file. This ensures that the password is not stored in plain text, improving security.