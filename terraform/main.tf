resource "aws_vpc" "default_c" {
  tags                             = merge(var.tags, {})
  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink_dns_support   = true
  enable_classiclink               = true
  cidr_block                       = var.vpc_cidr
  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "snet1_c" {
  vpc_id                  = aws_vpc.default_c.id
  tags                    = merge(var.tags, {})
  map_public_ip_on_launch = true
  cidr_block              = var.subnets[0]
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "snet2_c" {
  vpc_id                  = aws_vpc.default_c.id
  tags                    = merge(var.tags, {})
  map_public_ip_on_launch = true
  cidr_block              = var.subnets[1]
  availability_zone       = "us-east-1b"
}

resource "aws_internet_gateway" "gtw_c" {
  vpc_id = aws_vpc.default_c.id

  tags = {
    Name = "Brainboard k8s"
    Env  = "Development"
  }
}

resource "aws_route_table" "default_c" {
  vpc_id = aws_vpc.default_c.id
  tags   = merge(var.tags, {})

  route {
    gateway_id = aws_internet_gateway.gtw_c.id
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_route_table_association" "route-association-1_c" {
  subnet_id      = aws_subnet.snet1_c.id
  route_table_id = aws_route_table.default_c.id
}

resource "aws_route_table_association" "route-association-2_c" {
  subnet_id      = aws_subnet.snet2_c.id
  route_table_id = aws_route_table.default_c.id
}

resource "aws_iam_role" "default-iam_c" {
  tags               = merge(var.tags, {})
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy_c" {
  role       = aws_iam_role.default-iam_c.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly_c" {
  role       = aws_iam_role.default-iam_c.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy_c" {
  role       = aws_iam_role.default-iam_c.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_node_group" "default_c" {
  tags            = merge(var.tags, {})
  node_role_arn   = aws_iam_role.default-iam_c.arn
  node_group_name = "brainboard_k8s"
  cluster_name    = aws_eks_cluster.default_c.name

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy_c,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy_c,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly_c,
  ]

  scaling_config {
    min_size     = var.scaling.min
    max_size     = var.scaling.max
    desired_size = var.scaling.desired
  }

  subnet_ids = [
    aws_subnet.snet1_c.id,
    aws_subnet.snet2_c.id,
  ]
}

resource "aws_iam_role" "iam-cluster_c" {
  tags               = merge(var.tags, {})
  name               = "brainboard-k8s-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy_c" {
  role       = aws_iam_role.iam-cluster_c.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController_c" {
  role       = aws_iam_role.iam-cluster_c.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_security_group" "cluster-sg_c" {
  vpc_id      = aws_vpc.default_c.id
  tags        = merge(var.tags, {})
  name        = var.sg_name
  description = "Cluster communication with worker nodes"

  egress {
    to_port   = 0
    protocol  = "-1"
    from_port = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_security_group_rule" "cluster-ingress-workstation-https_c" {
  type              = "ingress"
  to_port           = 443
  security_group_id = aws_security_group.cluster-sg_c.id
  protocol          = "tcp"
  from_port         = 443
  description       = "Allow workstation to communicate with the cluster API Server"

  cidr_blocks = [
    var.workstation-external-cidr,
  ]
}

resource "aws_eks_cluster" "default_c" {
  role_arn = aws_iam_role.iam-cluster_c.arn
  name     = var.cluster-name

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy_c,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController_c,
  ]

  tags = {
    env      = "Staging"
    archUUID = "db83bcc0-696a-4f64-a6d5-fcc143caf3e2"
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.cluster-sg_c.id,
    ]
    subnet_ids = [
      aws_subnet.snet1_c.id,
      aws_subnet.snet2_c.id,
    ]
  }
}
resource "aws_ecr_repository" "ecr_repo" {
 name                 = var.ecr_repository_name
 image_tag_mutability = "IMMUTABLE"

 image_scanning_configuration {
   scan_on_push = true
 }
}

