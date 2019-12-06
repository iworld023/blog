###########
# BUILDER #
###########

# pull official base image
FROM python:3.8.0-alpine as builder

# set work directory
WORKDIR /usr/src/app

# set environment variables
# Prevent Ptyhon from writing pyc files to disc (equivalent to python -B option)
ENV PYTHONDONOTWRITBYTECODE 1
# Prevent Python from buffering stdout and stder (equivalent to python -u option)
ENV PYTHONBUFFERRED 1

# install psycopg2 dependencies
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

# lint
RUN pip install --upgrade pip
RUN pip install flake8
COPY . /usr/scr/app/
RUN flake8 --ignore=E501,F401 .

# install dependencies
COPY ./requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt



##########
# FINAL  #
##########

# pull official base image
FROM python:3.8.0-alpine


# create the directory for the app user
RUN mkdir -p /home/app

# Create the app user
RUN addgroup -S app && adduser -S app -G app

# create the appropriate directories
ENV HOME=/home/app
ENV APP_HOME=/home/app/WEB_ROOT
ENV WHEELS=/wheels
RUN mkdir ${APP_HOME}

# install dependencies
RUN apk update && apk add libpq
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache /wheels/*

# copy entrypoint-prod.sh
COPY ./entrypoint.prod.sh $APP_HOME

# copy project
COPY . $APP_HOME

# chown all the files to the app user
RUN chown -R app:app $APP_HOME

# change to the app user
USER app

# run entrypoint.prod.sh
ENTRYPOINT ["/home/app/web/entrypoint.prod.sh"]


