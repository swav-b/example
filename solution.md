# Check Cert MVP

### prerequisites:
* aws cli
* terraform

### how do i build the solution ?
```sh
aws configure
...
terraform init
...
terraform plan
...
terraform apply
```
### how do i test the solution ?
aws console > amazon api gateway > check_cert_api
click 'GET' under /check_cert > click test > enter query string > click test

### how do i deploy the solution to dev/qa/prod once i am happy with what i see ?
aws console > amazon api gateway > check_cert_api > drop down 'actions' > Deploy API

### once deployed to dev/qa/prod, how do i test it ?
please note, url will vary in your deployment. alter as needed.
```sh
curl -w ", status_code: %{http_code}" https://change_me.execute-api.us-east-1.amazonaws.com/prod/check_cert?hostname=www.google.com
{"expiration_date": "2023-02-20 08:19:00", "days_remaining": "60", "expired": false, "expires_in_less_than_30_days": false}, status_code: 200

curl -w ", status_code: %{http_code}" https://change_me.execute-api.us-east-1.amazonaws.com/prod/check_cert?hostname=not_a_url
error, status_code: 500

curl -w ", status_code: %{http_code}" https://change_me.execute-api.us-east-1.amazonaws.com/prod/check_cert?hostname=wwww.thisislikelynotarealsite.com
error, status_code: 500
```

### once done exploring, how do i destroy the environment ? 
```sh
terraform destroy
...
```

### what opportunities exist beyond MVP ?
Now that we see this is a viable path we should explore topics such as:
* deplpoy pipeline
* testing, unit and end-to-end
* auth, this endpoint is unprotected and could result in unnecessary charges if abused
* rate limiting, default rate limit is very high at 10k per minute, adjust accordingly to limit abuse