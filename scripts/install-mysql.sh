helm install drone \
  --set mysqlRootPassword=password,mysqlDatabase=drone \
    stable/mysql
