from diagrams import Diagram, Cluster
from diagrams.k8s.compute import Pod, Deployment, StatefulSet
from diagrams.k8s.network import Service, Ingress

from diagrams.onprem.gitops import ArgoCD

from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.queue import Kafka
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.onprem.security import Vault
from diagrams.elastic.elasticsearch import Elasticsearch
from diagrams.aws.storage import S3
from diagrams.onprem.client import Users

with Diagram("Kubernetes Deployment with ArgoCD", show=False, direction="TB"):

    with Cluster("Kubernetes Cluster"):
        ingress = Ingress("Ingress Controller")

        # ArgoCD Deployment
        with Cluster("GitOps with ArgoCD"):
            argo_cd = ArgoCD("ArgoCD")


        # Microservices
        with Cluster("Microservices"):
            user_service = Pod("User Service")
            order_service = Pod("Order Service")
            payment_service = Pod("Payment Service")
            product_service = Pod("Product Service")
            cart_service = Pod("Cart Service")
            inventory_service = Pod("Inventory Service")
            search_service = Pod("Search Service")


            pods = [user_service, order_service, payment_service, product_service, cart_service, inventory_service, search_service]

            svcs = []
            deployments = []
            for pod in pods:
                svcs.append(Service(f"{pod.label} SVC"))
                deployments.append(Deployment(f"{pod.label}"))
            
            for i in range(len(pods)):
                skip_ingress = [inventory_service]
                if pods[i] in skip_ingress:
                    svcs[i] >> pods[i] << deployments[i]
                else:
                    ingress >> svcs[i] >> pods[i] << deployments[i]


        # Event-Driven System
        with Cluster("Event-Driven System"):
            kafka = Kafka("Kafka Broker")
            order_service >> kafka >> inventory_service
            order_service >> kafka >> payment_service
            payment_service >> kafka >> inventory_service


        # Search Service using Elasticsearch
        with Cluster("Search Engine"):
            elasticsearch = Elasticsearch("Elasticsearch")
            search_service >> elasticsearch

        with Cluster("Databases & Caching"):
            ss = StatefulSet("PostgreSQL StatefulSet")
            db = PostgreSQL("PostgreSQL")
            cache = Redis("Redis Cache")

            user_service >> ss
            order_service >> ss
            payment_service >> ss
            ss >> db

        # Vault & Kubernetes Secrets
        with Cluster("Security"):
            vault = Vault("HashiCorp Vault")
            k8s_secrets = Vault("Kubernetes Secrets")
            vault >> k8s_secrets
            vault >> payment_service
            vault >> db

         # Monitoring Stack
        with Cluster("Monitoring"):
            prometheus = Prometheus("Prometheus")
            grafana = Grafana("Grafana")
            prometheus << grafana
            prometheus << pods

        # S3 Bucket for Product Images
        
    s3_bucket = S3("S3 - Product Images")
    product_service >> s3_bucket

    user = Users("Client")
    user >> ingress


