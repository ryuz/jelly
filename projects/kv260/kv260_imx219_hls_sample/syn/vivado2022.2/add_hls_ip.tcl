set_property  ip_repo_paths ../../hls [current_project]
update_ip_catalog
create_ip -name gaussian_filter  -vendor xilinx.com -library hls -version 1.0 -module_name gaussian_filter_0
create_ip -name laplacian_filter -vendor xilinx.com -library hls -version 1.0 -module_name laplacian_filter_0
