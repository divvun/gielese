# The process

TODO: login form
TODO: password + repeat validation
TODO: too many repeat attempts validation (tell user to back off)
TODO: brute force from specific IP -> block


## Testing / dev

Use `httpie` to produce requests until actual tests are written

## Steps

1.) User forgets password, and sends a request with their email:

    http -f POST \
        http://localhost:5000/user/forgot/ \
        email_address=cyclevalidation@gmail.com

2.) The backend sends an email with a reset token (itsdangerous). The
token is cryptographically signed with the timestamp, and contains the
username. The token is valid for 60 minutes.
g 
The backend also logs the attempt (tracking brute force attempts), and
logs the token (to prevent duplicate uses). 

3.) After receiving the email, the user follows a link to a page
produced by the backend. The user fills out a new password form, and
submits the following request:

        http -f POST 
        http://localhost:5000/user/reset/ \
        token=ImN5Y2xldmFsaWRhdGlvbiI.BYkpLA.mA544J91pplN8b7rEK9RPASSBL0 \
        new_password=somethingIcanRemember \
        repeat_password=somethingIcanRemember

This validates the token for time, whether it's been used, or whether
the signature has been tampered with. If validation is successful,
the new password is stored and the token is expired. The user may now
log back in.




