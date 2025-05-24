# User Management for Minecraft Authentication Portal

## Managing Users in users.json

This file contains instructions for managing users in the Minecraft Authentication Portal.

## File Structure

The `users.json` file contains an array of user objects. Each user object has the following structure:

```
{
    "username": "username_here",
    "password": "password_here",
    "note": "Optional description of the user",
    "access_duration": 12
}
```

## Fields Explanation

- `username`: The login name for the user (required)
- `password`: The user's password (required)
- `note`: Optional description or notes about the user
- `access_duration`: Time in hours that access is granted after authentication

## How to Edit

1. Stop the PHP container if it's running:
   ```
   docker-compose stop php
   ```

2. Edit the users.json file with your preferred text editor.

3. Make sure the file remains valid JSON:
   - Keep the square brackets at the beginning and end
   - Each user object must be enclosed in curly braces {}
   - Separate objects with commas
   - Don't leave trailing commas after the last object
   - All property names must be in double quotes

4. Save the file and restart the PHP container:
   ```
   docker-compose start php
   ```

## Example

```
[
    {
        "username": "alice",
        "password": "secure_password123",
        "note": "Alice - Regular player",
        "access_duration": 12
    },
    {
        "username": "bob",
        "password": "bob_minecraft_2023",
        "note": "Bob - Friend from work",
        "access_duration": 24
    }
]
```

## Troubleshooting

If users can't log in after editing the file:
1. Check for JSON syntax errors
2. Verify that the file permissions allow the PHP container to read it
3. Restart the PHP container to reload the user data