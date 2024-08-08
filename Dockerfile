FROM public.ecr.aws/lambda/python:3.9

COPY  container-github-lza-config-file-update-sf.py ${LAMBDA_TASK_ROOT}
COPY script.sh ${LAMBDA_TASK_ROOT}
RUN curl -o /etc/yum.repos.d/gh-cli.repo https://cli.github.com/packages/rpm/gh-cli.repo
RUN yum install git -y
RUN yum install -y gh
CMD [ "container-github-lza-config-file-update-sf.lambda_handler" ]