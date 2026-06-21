##
# module "network" {
#   source   = "./modules/network"
#   env      = var.env
#   region   = var.region
#   zone1    = var.zone1
#   zone2    = var.zone2
#   zone3    = var.zone3
#   eks_name = var.eks_name
# }

module "ecr" {
  source = "./modules/ecr"
}

# module "eks" {
#   source             = "./modules/eks"
#   env                = var.env
#   eks_name           = var.eks_name
#   eks_version        = var.eks_version
#   private_subnet_ids = module.network.private_subnet_ids
# }
