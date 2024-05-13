ARG FUNCTION_DIR="/function"

FROM public.ecr.aws/docker/library/python:3.11-slim as build-image

ARG FUNCTION_DIR

RUN mkdir -p ${FUNCTION_DIR}
COPY . ${FUNCTION_DIR}
WORKDIR ${FUNCTION_DIR}

RUN pip install --upgrade pip

RUN pip install --no-cache-dir -r requirements.txt --target ${FUNCTION_DIR}

RUN pip install \
    --target ${FUNCTION_DIR} \
    awslambdaric

FROM public.ecr.aws/docker/library/python:3.11-slim

ARG FUNCTION_DIR

WORKDIR ${FUNCTION_DIR}

COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]