set_property  ip_repo_paths ../../hls [current_project]
update_ip_catalog
create_ip -name video_filter -vendor xilinx.com -library hls -version 1.0 -module_name video_filter_0
