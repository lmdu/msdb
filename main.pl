#!/usr/bin/perl
use strict;
use Tkx;
use File::Basename;
use File::Copy qw(copy move);
use Cwd qw(cwd);
use DBI;
use ActiveState::Browser;
use Spreadsheet::WriteExcel;
use POSIX qw(ceil);
Tkx::lappend('::auto_path', 'lib');
Tkx::package_require('tkdnd');
Tkx::package_require('img::png');
Tkx::package_require('img::ico');
Tkx::package_require('tooltip');
Tkx::package_require('widget::statusbar');
Tkx::namespace_import("::tooltip::tooltip");
Tkx::option_add("*TEntry.cursor", "xterm");

# include func file
#do 'func.pl';

# widget hash

our %widget;

# parameter hash

our %paras;
$paras{repeat_stream}="12-7-5-4-4-4";
$paras{repeat_length}=12;
$paras{motif_flag}=1;
$paras{distance}=10;
$paras{uid} = 0;
$paras{process_file}=0;
$paras{statway}="whole";
$paras{type_table}=1;
$paras{length_table}=1;
$paras{repeats_table}=1;
$paras{ssrtype_table}=1;
$paras{pure_table} = 1;
$paras{cpd_table} = 1;
$paras{cpx_table} = 1;
$paras{time_flag}="cancel";
$paras{filedir} = $paras{lastdir} = cwd;

# globe gui variable
our $times="00:00:00";
our $mw;
our $min_repeat_entry;
our $file_tree;
our $outpath = cwd;
our $min_repeat_num = 5;
our $end_base_num = 200;
our $file_num = 0;
our $file_num_info;
our $base_num;
our $total_progress = '0%';
our $total_pro_bar = 0;
our $run_progress;
our $action = 1;
our $set_para_panel;
our $detail_para;
our $repeatunite = 3;
our $input_repeat_unite = "AC";
our $repeat_no_type = 0;
our $type_panel;
our $max_repeats;
our $pro_gress_bar;

# file format extension
our @extensions=(".txt", ".fa", ".gb", ".embl", ".genbank", ".iembl", ".fasta");


# main windows
creat_win();

# create windows function
sub creat_win{
    # menubar
    $file_num = 0;
    $run_progress = 'Welcome to MSDB!';
    $mw = Tkx::widget->new(".");
    $mw->g_wm_title('MSDBv2.4.2');
	$mw->g_grid_columnconfigure(0, -weight => 1);
	$mw->g_grid_rowconfigure(1, -weight => 1);
	#different os
	$widget{'os'}=Tkx::tk_windowingsystem();
	if($widget{'os'} eq "win32"){
		Tkx::wm_iconbitmap($mw, -default => "MSDB.ico");
	} elsif($widget{'os'} eq "x11"){
		Tkx::wm_iconphoto($mw, "-default", Tkx::image_create_photo(-file => 'MSDB.ico'));
	}
	###############
    Tkx::option_add("*tearOff", 0);
    my $menu = $mw->new_menu;
    $mw->configure(-menu => $menu);
    my $m_file = $menu->new_menu;
	my $m_edit = $menu->new_menu;
	$widget{m_action}=$menu->new_menu;
	my $m_link = $menu->new_menu;
    my $m_help = $menu->new_menu;
    $menu->add_cascade(-menu => $m_file, -label => 'File');
    $menu->add_cascade(-menu => $m_edit, -label => "Edit");
	$menu->add_cascade(-menu => $widget{m_action}, -label => "Tools");
	$menu->add_cascade(-menu => $m_link, -label => "Links");
    $menu->add_cascade(-menu => $m_help, -label => 'Help');
    $m_file->add_command(-label => 'Add File', -command => sub {add_files()});
    $m_file->add_command(-label => 'Add Folder', -command => sub {add_folder()});
	$m_file->add_separator;
    $m_file->add_command(-label => 'Exit', -command => sub {exit});
	$m_edit->add_command(-label => "Cut", -accelerator => "Ctrl+X", -command => sub{Tkx::event_generate(Tkx::focus(), "<<Cut>>")});
	$m_edit->add_command(-label => "Copy", -accelerator => "Ctrl+C", -command => sub{Tkx::event_generate(Tkx::focus(), "<<Copy>>")});
	$m_edit->add_command(-label => "Paste", -accelerator => "Ctrl+V", -command => sub{Tkx::event_generate(Tkx::focus(), "<<Paste>>")});
	$m_edit->add_command(-label => "Clear", -accelerator => "DEL", -command => sub{Tkx::event_generate(Tkx::focus(), "<<Clear>>")});
	$m_edit->add_separator;
	$m_edit->add_command(-label => "Delete selected file", -command => sub{del_tree_item()});
	$m_edit->add_command(-label => "Delete all files", -command => sub{clean_tree()});
	$widget{m_action}->add_command(-label => "Sequence Segmentation", -command => sub{create_seq_seg()});
	$widget{m_action}->add_command(-label => "Sliding Window Plot", -command => sub{exe_chart()});
	$widget{m_action}->add_command(-label => "Search Within Results", -command => sub{exe_search()});
	$widget{m_action}->add_separator;
	$widget{m_action}->add_command(-label => "Start Search", -command => sub{main_func($action);});
	
	#bind..
	$mw->g_bind("<3>", [sub {my($x, $y) = @_; $m_edit->g_tk___popup($x,$y)},Tkx::Ev("%X", "%Y")]);
	
    $m_link->add_command(-label => "NCBI Database", -command => sub{ActiveState::Browser::open("http://www.ncbi.nlm.nih.gov/")});
	$m_link->add_command(-label => "EMBL Database", -command => sub{ActiveState::Browser::open("http://www.ebi.ac.uk/embl/")});
	$m_link->add_separator;
	$m_link->add_command(-label => "UCSC Genome Browser", -command => sub{ActiveState::Browser::open("http://genome.ucsc.edu/")});
	$m_link->add_command(-label => "Ensembl Genome Browser", -command => sub{ActiveState::Browser::open("http://www.ensembl.org/")});
    $m_help->add_command(-label => "Help Contents", -command => sub {ActiveState::Browser::open("readme.html")});
	$m_help->add_separator;
	$m_help->add_command(-label => "MSDB Homepage", -command => sub{ActiveState::Browser::open("http://msdb.biosv.com/")});
	$m_help->add_separator;
    $m_help->add_command(-label => "About MSDB", -command => sub {about()});
    
	
	# tool bar
	my $toolbar = $mw->new_ttk__frame(-borderwidth => 1, -padding => 4, -relief => "groove");
	$toolbar->g_grid(-column => 0, -row => 0, -sticky => "we");
	my $ico1 = $toolbar->new_ttk__button(-text => "add file", -style => "Toolbutton", -compound => "image", -width => 0, -command => sub{add_files()}, -image => Tkx::image_create_photo(-file => 'images/addfile.png'));
	$ico1->g_grid(-column => 0, -row => 0);
	Tkx::tooltip($ico1, "add file");
	my $ico2 = $toolbar->new_ttk__button(-text => "add folder", -style => "Toolbutton", -compound => "image", -width => 0, -command => sub{add_folder()}, -image => Tkx::image_create_photo(-file => 'images/addfiles.png'));
	$ico2->g_grid(-column => 1, -row => 0);
	Tkx::tooltip($ico2, "add folder");
	my $ico3 = $toolbar->new_ttk__button(-style => "Toolbutton", -compound => "image", -width => 0, -command => sub{create_seq_seg()}, -image => Tkx::image_create_photo(-file => 'images/split.png'));
	$ico3->g_grid(-column => 2, -row => 0);
	Tkx::tooltip($ico3, "Sequence Segmentation");
	my $ico4 = $toolbar->new_ttk__button(-style => "Toolbutton", -compound => "image", -width => 0, -command => sub{exe_chart()}, -image => Tkx::image_create_photo(-file => 'images/chart.png'));
	$ico4->g_grid(-column => 3, -row => 0);
	Tkx::tooltip($ico4, "Sliding Window Plot");
	my $ico5 = $toolbar->new_ttk__button(-style => "Toolbutton", -compound => "image", -width => 0, -command => sub{exe_search()}, -image => Tkx::image_create_photo(-file => 'images/search.png'));
	$ico5->g_grid(-column => 4, -row => 0);
	Tkx::tooltip($ico5, "Search Within Results");
	
	
	
	my $ico6 = $toolbar->new_ttk__button(-text => "help", -style => "Toolbutton", -compound => "image", -width => 0, -command => sub{ActiveState::Browser::open("readme.html")}, -image => Tkx::image_create_photo(-file => 'images/help.png'));
	$ico6->g_grid(-column => 5, -row => 0);
	Tkx::tooltip($ico6, "view help");
			# output path
    my $outpath_label = $toolbar->new_ttk__label(-text => "Output directory:", -anchor => "e");
	$outpath_label->g_grid(-column => 6, -row => 0, -sticky => "e");
	$toolbar->g_grid_columnconfigure(6, -weight => 1);
    my $outpath_entry = $toolbar->new_ttk__entry(-textvariable => \$outpath, -width=> 35);
    $outpath_entry->g_grid(-column => 7, -row => 0, -sticky => "e");
    my $outpath_bn = $toolbar->new_ttk__button(-text => 'Browse', -command => sub{ select_out_path()});
    $outpath_bn->g_grid(-column => 8, -row => 0, -sticky => "e");
	my $open_bn = $toolbar->new_ttk__button(-text => "Open", -command => sub{open_dir($outpath)});
	$open_bn->g_grid(-column => 9, -row => 0, -sticky => "e");

    # main content

    my $main_frame = $mw->new_ttk__frame(-padding => "5");
    $main_frame->g_grid(-column => 0, -row => 1, -sticky => "wnes");
	$main_frame->g_grid_columnconfigure(0, -weight => 1);
	$main_frame->g_grid_rowconfigure(0, -weight => 1);

    # your add files panel
    my $add_file_panel = $main_frame->new_ttk__labelframe(-text => "Files list :", -padding => "5");
    $add_file_panel->g_grid(-column => 0, -row => 0, -sticky => "wnes", -padx => "0 10");
	$add_file_panel->g_grid_columnconfigure(0, -weight => 1);
	$add_file_panel->g_grid_rowconfigure(0, -weight => 1);
            #add file tree view
    $file_tree = $add_file_panel->new_ttk__treeview(
		-columns => "file size state",
		-show => 'headings',
	);
    $file_tree->g_grid(-column => 0, -row => 0, -columnspan => 5, -sticky => "wnes");
    $file_tree->column("size", -width => 120, -anchor => "center", -stretch => 1);
    $file_tree->column("file", -width => 240, -stretch => 1);
	#$file_tree->column("format", -width => 100, -anchor => 'center', -stretch => 1);
	$file_tree->column("state", -width => 120, -anchor => 'center', -stretch => 1);
    $file_tree->heading("size", -text => 'Size');
	#$file_tree->heading('format', -text => 'Format');
	$file_tree->heading('state', -text => 'Status');
    $file_tree->heading("file", -text => 'File Name');
	
	#drag file
	Tkx::tkdnd__drop___target_register($file_tree,'*');
	Tkx::bind($file_tree, '<<Drop:DND_Files>>', [sub{drag_file(shift)}, Tkx::Ev('%D')]);
	
    my $tree_scrollbar = $add_file_panel->new_ttk__scrollbar(-orient => 'vertical', -command => [$file_tree, 'yview']);
    $tree_scrollbar->g_grid(-column => 5, -row => 0, -sticky => "ns");
    $file_tree->configure(-yscrollcommand => [$tree_scrollbar, 'set']);
            #add file status
    $add_file_panel->new_ttk__label(-textvariable => \$file_num_info, -width => 35)->g_grid(-column => 0, -row => 1, -sticky => "we", -pady => "5");
            #delete item from tree
	my $add_item = $add_file_panel->new_ttk__button(-text => "add file", -command => sub {add_files()}, -style => "Toolbutton", -width => 0, -image => Tkx::image_create_photo(-file => 'images/file.png'));
	$add_item->g_grid(-column => 1, -row => 1);
	Tkx::tooltip($add_item, "add file");
	my $add_items = $add_file_panel->new_ttk__button(-text => "add folder", -command => sub {add_folder()}, -style => "Toolbutton", -width => 0, -image => Tkx::image_create_photo(-file => 'images/folder.png'));
	$add_items->g_grid(-column => 2, -row => 1);
	Tkx::tooltip($add_items, "add all files in a folder");
    my $del_item_bn = $add_file_panel->new_ttk__button(-text => 'remove', -command => sub{del_tree_item()}, -style => "Toolbutton", -width => 0, -image => Tkx::image_create_photo(-file => 'images/delete.png'));
    $del_item_bn->g_grid(-column => 3, -row => 1);
	Tkx::tooltip($del_item_bn, "delete the selected file");
    my $del_list_bn = $add_file_panel->new_ttk__button(-text => 'clear', -command => sub{clean_tree()}, -style => "Toolbutton", -width => 0, -image => Tkx::image_create_photo(-file => 'images/clear.png'));
    $del_list_bn->g_grid(-column => 4, -row => 1);
	Tkx::tooltip($del_list_bn, "delete all files");
	
	# parameter control panel
	my $paras_control_panel = $main_frame->new_ttk__frame;
	$paras_control_panel->g_grid(-column => 2, -row => 0, -sticky => "wnes");
	$paras_control_panel->g_grid_rowconfigure(0, -weight => 2);
	$paras_control_panel->g_grid_rowconfigure(1, -weight => 1);

    # parameter setting panel
    $set_para_panel = $paras_control_panel->new_ttk__labelframe(-text => "Search Module :", -padding => "5");
    $set_para_panel->g_grid(-column => 0, -row => 0, -sticky => "wens");
	
	# software function
	my $action_label = $set_para_panel->new_ttk__label(-text => "Mode: ");
	$action_label->g_grid(-column => 0, -row => 0);
	my @actions = ("Perfect Search", "Imperfect Search");
	my $vaction;
	my $select_action = $set_para_panel->new_ttk__combobox(-values => \@actions, -textvariable => \$vaction, -state => "readonly", -width => 20);
	$select_action->g_grid(-column => 1, -row => 0);
	$select_action->current(0);
	$select_action->g_bind("<<ComboboxSelected>>", sub {$action = change_mode($vaction)});
	
	# separator
	
	$set_para_panel->new_ttk__separator(-orient => 'horizontal')->g_grid(-column => 0, -row => 1, -sticky => "we", -columnspan => 2, -pady=> 5);
	
	# detail parameter panel
	
	# mode select
	
	normal_mode();
	
	# flanking sequence length
	
	$set_para_panel->new_ttk__label(
		-text => 'Flanking Sequence Length:',
	)->g_grid(
		-column => 0,
		-row => 3,
		-columnspan => 2,
		-sticky => "w",
		-padx => "10 0",
	);
	$set_para_panel->new_ttk__entry(
		-textvariable => \$end_base_num,
	)->g_grid(
		-column => 0,
		-row => 4,
		-columnspan => 2,
		-sticky => "w",
		-padx => "10 0",
	);
	
	# statistics control panel
	my $set_stat = $paras_control_panel->new_ttk__labelframe(-text => "Statistics :", -padding => 5);
	$set_stat->g_grid(-column => 0, -row => 1, -sticky => "wens", -pady => 5);
	#######statistic
	$set_stat->new_ttk__label(-text => "Statistic by :")->g_grid(-column => 0, -row=>0, -sticky => "w");
	$set_stat->new_ttk__radiobutton(
		-text => "sequence", 
		-variable=>\$paras{statway}, 
		-value => "file",
	)->g_grid(
		-column => 1,
		-row => 0,
		-sticky => "w",
	);
	$set_stat->new_ttk__radiobutton(
		-text => "whole",
		-variable => \$paras{statway},
		-value => "whole",
	)->g_grid(
		-column => 2,
		-row => 0,
		-sticky => "w",
	);
	$widget{perfect_stat} = $set_stat->new_ttk__frame;
	$widget{perfect_stat}->g_grid(
		-column => 0,
		-row => 1,
		-sticky => 'wnes',
		-columnspan => 3,
	);
	$widget{perfect_stat}->new_ttk__checkbutton(
		-text => "Display motif type statistic",
		-variable => \$paras{type_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 0,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{perfect_stat}->new_ttk__checkbutton(
		-text => "Display motif length statistic",
		-variable => \$paras{length_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 1,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{repeats_table} = $widget{perfect_stat}->new_ttk__checkbutton(
		-text => "Display motif repeats statistic",
		-variable => \$paras{repeats_table},
		-offvalue => 0,
		-onvalue => 1,
	);
	$widget{repeats_table}->g_grid(
		-column => 0,
		-row => 2,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{imperfect_stat} = $set_stat->new_ttk__frame;
	$widget{imperfect_stat}->new_ttk__checkbutton(
		-text => "Display ssr type statistic",
		-variable => \$paras{ssrtype_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 0,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{imperfect_stat}->new_ttk__checkbutton(
		-text => "Display pure ssr statistic",
		-variable => \$paras{pure_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 1,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{imperfect_stat}->new_ttk__checkbutton(
		-text => "Display compound ssr statistic",
		-variable => \$paras{cpd_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 2,
		-sticky => "w",
		-pady => "3 0",
	);
	$widget{imperfect_stat}->new_ttk__checkbutton(
		-text => "Display complex ssr statistic",
		-variable => \$paras{cpx_table},
		-offvalue => 0,
		-onvalue => 1,
	)->g_grid(
		-column => 0,
		-row => 3,
		-sticky => "w",
		-pady => "3 0",
	);
	
	#start button
	$widget{start_bn}=$paras_control_panel->new_ttk__button(
		-text => "Start Search Microsatellite",
		-image => Tkx::image_create_photo(-file => 'images/start.png'),
		-compound => "left",
		-command => sub{main_func($action)},
	);
	$widget{start_bn}->g_grid(
		-column => 0,
		-row => 2,
		-sticky => "wnes",
	);
	
    
    #status bar
    my $status_bar = $mw->new_widget__statusbar(-ipad => [1, 2]);#(-borderwidth => 1, -relief => "groove");
    $status_bar->g_grid(-column => 0, -row => 2, -sticky => "we", -pady => "5 0");
    my $sbar_lb1 = $status_bar->new_ttk__label(-textvariable => \$run_progress, -anchor => "w", -width => 40);
	$status_bar->add($sbar_lb1, -weight => 1);
	my $sb_file_label = $status_bar->new_ttk__label(-text => "Files:");
	$status_bar->add($sb_file_label, -separator => 1);
	my $sb_file_num = $status_bar->new_ttk__label(-textvariable => \$file_num, -width => 6, -anchor => "w");
	$status_bar->add($sb_file_num);
	my $sb_process_label = $status_bar->new_ttk__label(-text => "Processed:");
	$status_bar->add($sb_process_label);
	my $sb_process_num = $status_bar->new_ttk__label(-textvariable => \$paras{process_file}, -width => 6, -anchor => "w");
	$status_bar->add($sb_process_num);
	my $sb_pro_time = $status_bar->new_ttk__label(-textvariable => \$times, -anchor => 'w');
	$status_bar->add($sb_pro_time, -separator => 1);
	$pro_gress_bar=$status_bar->new_ttk__progressbar(-orient => 'horizontal', -length => 100, -mode => 'indeterminate');
	$status_bar->add($pro_gress_bar, -separator => 1);
	my $pro_gress_num = $status_bar->new_ttk__label(-width => 0, -anchor => "w");
	$status_bar->add($pro_gress_num);
  
    Tkx::MainLoop;
}
sub change_mode{
	my $mode = shift;
	if($mode eq "Perfect Search"){
		$widget{imperfect_stat}->g_grid_forget;
		$widget{perfect_stat}->g_grid(
			-column => 0,
			-row => 1,
			-sticky => 'wnes',
			-columnspan => 3,
		);
		normal_mode();
		return 1;
	} else {
		$widget{perfect_stat}->g_grid_forget;
		$widget{imperfect_stat}->g_grid(
			-column => 0,
			-row => 1,
			-sticky => 'wnes',
			-columnspan => 3,
		);
		run_status("select imperfect search module");
		seq_mode();
		return 2;
	}
}
sub change_type{
	my $in = shift;
	if($in eq "nucleotide number"){
		run_status("select the number of nucleotide of motif");
		create_base_no();
		return 1;
	} elsif($in eq "custom motif") {
		run_status("select custom input motif");
		create_input_unite();
		return 2;
	} else {
		run_status("select search all motifs");
		create_all_motifs();
		return 3;
	}
}
sub change_repeat{
	my ($in, $widget) = shift;
	Tkx::destroy($widget);
	$widget = $widget{'min_repeat_panel'}->new_ttk__frame;
	$widget->g_grid(-column => 0, -row => 2, -sticky => "wens");
	if($in ne "interval repeats"){
		$widget->new_ttk__entry(-textvariable => \$min_repeat_num)->g_grid(-column => 0, -row => 0, -sticky => "w");
	} else {
		$widget->new_ttk__label(-text => "Min :")->g_grid(-column => 0, -row => 0);
		$widget->new_ttk__entry(-textvariable => \$min_repeat_num, -width => 5)->g_grid(-column => 1, -row => 0);
		$widget->new_ttk__label(-text => "Max :")->g_grid(-column => 2, -row => 0, -padx => "5 0");
		$widget->new_ttk__entry(-textvariable => \$max_repeats, -width => 5)->g_grid(-column => 3, -row => 0);
	}
	if($in eq "minimum repeats"){
		$widget{repeats_table}->configure(-state => "normal");
		run_status("select input minimum repeats");
		$paras{repeats_table} = 1;
		return 0;
	} elsif ($in eq "precise repeats"){
		$widget{repeats_table}->configure(-state => "disabled");
		run_status("select input precise repeats");
		$paras{repeats_table} = 0;
		return 1;
	} else {
		$widget{repeats_table}->configure(-state => "normal");
		run_status("select input a range of repeats");
		$paras{repeats_table} = 1;
		return 2;
	}
}
sub normal_mode{
	#destroy panel
	Tkx::destroy($detail_para);
	$detail_para = $set_para_panel->new_ttk__frame(-padding => "10 0 0 0");
	$detail_para->g_grid(-column => 0, -row => 2, -sticky => "wens", -columnspan => 2);
			# mode label
	$detail_para->new_ttk__label(-text => "Type of Motif :", -anchor => "w")->g_grid(-column => 0, -row => 0, -sticky => "w", -pady => "0 5");
	my @repeatunite = ("search all motifs","nucleotide number", "custom motif");
	my $vrepeatunite;
    my $select_base_num = $detail_para->new_ttk__combobox(-values => \@repeatunite, -textvariable => \$vrepeatunite, -state => "readonly");
    $select_base_num->g_grid(-column => 0, -row => 1, -sticky => "w");
	$select_base_num->current(0);
	$select_base_num->g_bind("<<ComboboxSelected>>", sub{$repeatunite = change_type($vrepeatunite)});
	create_all_motifs();
}
sub create_base_no{
	Tkx::destroy($type_panel);
	$type_panel = $detail_para->new_ttk__frame(-padding => 0);
	$type_panel->g_grid(-column => 0, -row => 2, -sticky => "wens", -pady => 5);
	my $one = $type_panel->new_ttk__radiobutton(-text => "1 (mono-)", -variable => \$base_num, -value => "1");
    $one->g_grid(-column => 0, -row => 0, -sticky => "w");
    my $two = $type_panel->new_ttk__radiobutton(-text => "2 (di-)", -variable => \$base_num, -value => "2");
    $two->g_grid(-column => 1, -row => 0, -sticky => "w");
    $two->invoke;
    my $three = $type_panel->new_ttk__radiobutton(-text => "3 (tri-)", -variable => \$base_num, -value => "3");
    $three->g_grid(-column => 0, -row => 1, -sticky => "w");
    my $four = $type_panel->new_ttk__radiobutton(-text => "4 (tetra-)", -variable => \$base_num, -value => "4");
    $four->g_grid(-column => 1, -row => 1, -sticky => "w");
    my $five = $type_panel->new_ttk__radiobutton(-text => "5 (penta-)", -variable => \$base_num, -value => "5");
    $five->g_grid(-column => 0, -row => 2, -sticky => "w");
    my $six = $type_panel->new_ttk__radiobutton(-text => "6 (hexa-)", -variable => \$base_num, -value => "6");
    $six->g_grid(-column => 1, -row => 2, -sticky => "w");
	            #repeat number
	$widget{'min_repeat_panel'} = $type_panel->new_ttk__frame;
	$widget{'min_repeat_panel'}->g_grid(-column=>0, -row=>3, -columnspan=>2);
	my $repeat_panel;
	my $repeat_no_label = $widget{'min_repeat_panel'}->new_ttk__label(-text => "Number of repeats :");
	$repeat_no_label->g_grid(-column => 0, -row => 0,-sticky => "w");
	my @types = ("minimum repeats", "precise repeats", "interval repeats");
	my $vrepeat_no_type;
	my $type_no = $widget{'min_repeat_panel'}->new_ttk__combobox(-values => \@types, -textvariable => \$vrepeat_no_type, -state => "readonly");
	$type_no->g_grid(-column => 0, -row => 1, -sticky => "w", -pady => 5);
	$type_no->current(0);
	$type_no->g_bind("<<ComboboxSelected>>", sub{$repeat_no_type = change_repeat($vrepeat_no_type, $repeat_panel)});
	$repeat_panel = $widget{'min_repeat_panel'}->new_ttk__frame;
	$repeat_panel->g_grid(-column => 0, -row => 2, -sticky => "wens");
    $min_repeat_entry = $repeat_panel->new_ttk__entry(-textvariable => \$min_repeat_num);
    $min_repeat_entry->g_grid(-column => 0, -row => 0, -sticky => "w");
}
sub create_input_unite{
	Tkx::destroy($type_panel);
	$type_panel = $detail_para->new_ttk__frame;
	$type_panel->g_grid(-column => 0, -row => 2, -sticky => "wens", -pady => 5);
	my $input = $type_panel->new_ttk__entry(-textvariable => \$input_repeat_unite);
	$input->g_grid(-column => 0, -row => 0);
	my $label = $type_panel->new_ttk__label(-text => "e.g. AT, AGC, AAAG\nseparate motifs with \" \" or \",\"");
	$label->g_grid(-column => 0, -row => 1, -pady => 3);
	#repeat number
	$widget{'min_repeat_panel'} = $type_panel->new_ttk__frame;
	$widget{'min_repeat_panel'}->g_grid(-column=>0, -row=>2, -columnspan=>2);
	my $repeat_panel;
	my $repeat_no_label = $widget{'min_repeat_panel'}->new_ttk__label(-text => "Number of repeats :");
	$repeat_no_label->g_grid(-column => 0, -row => 0,-sticky => "w");
	my @types = ("minimum repeats", "precise repeats", "interval repeats");
	my $vrepeat_no_type;
	my $type_no = $widget{'min_repeat_panel'}->new_ttk__combobox(-values => \@types, -textvariable => \$vrepeat_no_type, -state => "readonly");
	$type_no->g_grid(-column => 0, -row => 1, -sticky => "w", -pady => 5);
	$type_no->current(0);
	$type_no->g_bind("<<ComboboxSelected>>", sub{$repeat_no_type = change_repeat($vrepeat_no_type, $repeat_panel)});
	$repeat_panel = $widget{'min_repeat_panel'}->new_ttk__frame;
	$repeat_panel->g_grid(-column => 0, -row => 2, -sticky => "wens");
    $min_repeat_entry = $repeat_panel->new_ttk__entry(-textvariable => \$min_repeat_num);
    $min_repeat_entry->g_grid(-column => 0, -row => 0, -sticky => "w");
}
sub create_all_motifs{
	Tkx::destroy($type_panel);
	$type_panel=$detail_para->new_ttk__frame;
	$type_panel->g_grid(-column => 0, -row => 2, -sticky => "wens", -pady => 5);
	my ($w1, $w2, $w3, $w4);
	$type_panel->new_ttk__radiobutton(-text => "Minimum repeats", -value => 1, -variable => \$paras{motif_flag}, -command => sub{disable_motif($paras{motif_flag}, $w1, $w2, $w3, $w4)})->g_grid(-column=> 0, -row => 0, -sticky => "w");
	$w1 = $type_panel->new_ttk__entry(-textvariable => \$paras{repeat_stream});
	$w1->g_grid(-column => 0, -row => 1);
	$w2 = $type_panel->new_ttk__label(-text => "mono-di-tri-tetra-penta-hexa");
	$w2->g_grid(-column => 0, -row => 2);
	$type_panel->new_ttk__radiobutton(-text => "Minimum length", -value => 2, -variable => \$paras{motif_flag}, -command => sub{disable_motif($paras{motif_flag}, $w1, $w2, $w3, $w4)})->g_grid(-column=> 0, -row => 3, -sticky => "w", -pady => "5 0");
	$w3 = $type_panel->new_ttk__entry(-textvariable => \$paras{repeat_length}, -state => "disabled");
	$w3->g_grid(-column => 0, -row => 4);
	$w4 = $type_panel->new_ttk__label(-text => "Length of microsatellite", -state => "disabled");
	$w4->g_grid(-column => 0, -row => 5);
}
sub disable_motif{
	my ($flag, $wg1, $wg2, $wg3, $wg4) = @_;
	if($flag==1){
		$wg1->configure(-state => "normal");
		$wg2->configure(-state => "normal");
		$wg3->configure(-state => "disabled");
		$wg4->configure(-state => "disabled");
	}else{
		$wg3->configure(-state => "normal");
		$wg4->configure(-state => "normal");
		$wg1->configure(-state => "disabled");
		$wg2->configure(-state => "disabled");
	}
}
sub seq_mode{
	#destroy panel
	Tkx::destroy($detail_para);
	$detail_para = $set_para_panel->new_ttk__frame;
	$detail_para->g_grid(-column => 0, -row => 2, -sticky => "wens", -columnspan => 2);
	$detail_para->new_ttk__label(-text => "Repeats or length :")->g_grid(-column => 0, -row => 0, -sticky => "w");
	my ($w1, $w2, $w3, $w4);
	$detail_para->new_ttk__radiobutton(-text => "Minimum repeats", -value => 1, -variable => \$paras{motif_flag}, -command => sub{disable_motif($paras{motif_flag}, $w1, $w2, $w3, $w4)})->g_grid(-column=> 0, -row => 1, -sticky => "w");
	$w1 = $detail_para->new_ttk__entry(-textvariable => \$paras{repeat_stream});
	$w1->g_grid(-column => 0, -row => 2);
	$w2 = $detail_para->new_ttk__label(-text => "mono-di-tri-tetra-penta-hexa");
	$w2->g_grid(-column => 0, -row => 3);
	$detail_para->new_ttk__radiobutton(-text => "Minimum length", -value => 2, -variable => \$paras{motif_flag}, -command => sub{disable_motif($paras{motif_flag}, $w1, $w2, $w3, $w4)})->g_grid(-column=> 0, -row => 4, -sticky => "w");
	$w3 = $detail_para->new_ttk__entry(-textvariable => \$paras{repeat_length}, -state => "disabled");
	$w3->g_grid(-column => 0, -row => 5);
	$w4 = $detail_para->new_ttk__label(-text => "Length of microsatellite", -state => "disabled");
	$w4->g_grid(-column => 0, -row => 6);
	$detail_para->new_ttk__label(-text => "Maximum distance :", -anchor => "w")->g_grid(-column=>0, -row=>7, -sticky => "w", -pady => "5 0");
	$detail_para->new_ttk__entry(-textvariable => \$paras{distance})->g_grid(-column => 0, -row => 8);
}
sub create_seq_seg{
	my $large_file;
	my $op_dir;
	my $sw = $mw->new_toplevel();
	$sw->g_wm_title("Sequence Segmentation");
	my $sf = $sw->new_ttk__frame(-padding => 20);
	$sf->g_grid(-sticky => "wnes");
	$sf->new_ttk__label(
		-text => "Select large genome sequence file:",
	)->g_grid(
		-sticky => "w",
		-column => 0,
		-row => 0,
		-columnspan => 2,
	);
	$sf->new_ttk__entry(
		-textvariable => \$large_file,
		-width => 50,
	)->g_grid(
		-sticky => "we",
		-column => 0,
		-row => 1,
	);
	$sf->new_ttk__button(
		-text => "Browser",
		-command => sub{
			my $file = Tkx::tk___getOpenFile(-parent => $sw);
			return if !$file;
			$large_file = $file;
		}
	)->g_grid(
		-column => 1,
		-row => 1,
		-sticky => "w",
	);
	
	$sf->new_ttk__label(
		-text => "Note: Input file can be fasta, embl or genbank sequence file\n which contains multiple records",
	)->g_grid(
		-column => 0,
		-row => 2,
		-columnspan => 2,
		-sticky => "w",
	);
	
	$sf->new_ttk__label(
		-text => "Select output directory:",
	)->g_grid(
		-sticky => "w",
		-column => 0,
		-row => 3,
		-columnspan => 2,
		-pady => "10 0",
	);
	$sf->new_ttk__entry(
		-textvariable => \$op_dir,
		-width => 50,
	)->g_grid(
		-sticky => "we",
		-column => 0,
		-row => 4,
	);
	$sf->new_ttk__button(
		-text => "Browser",
		-command => sub{
			my $dir = Tkx::tk___chooseDirectory(-parent => $sw);
			return if !$dir;
			$op_dir = $dir;
		}
	)->g_grid(
		-column => 1,
		-row => 4,
		-sticky => "w",
	);
	$sf->new_ttk__progressbar(
		-mode => "determinate",
		-orient => "horizontal",
		-variable => \$paras{sw_probar},
		-maximum => 1,
	)->g_grid(
		-column => 0,
		-row => 5,
		-sticky => "we",
		-pady => "10 0",
	);
	$sf->new_ttk__button(
		-text => "Segment",
		-command => sub{seq_segment($large_file, $op_dir, $sw)},
	)->g_grid(
		-column => 1,
		-row => 5,
		-sticky => "w",
		-pady => "10 0",
	);
}

# main function for the program
# gui function
sub choose_dir{
    my $dir = Tkx::tk___chooseDirectory(
		-initialdir => $paras{lastdir},
	);
    return unless $dir;
	$paras{lastdir} = $dir;
	return $dir;
}
sub select_out_path{
    my $op = choose_dir();
    $outpath = $op if $op;
}
sub choose_file{
    my $file = Tkx::tk___getOpenFile(
		-multiple => 1,
		-initialdir => \$paras{filedir},
	);
	return unless $file;
	$paras{filedir} = dirname($file);
	return $file;
}
sub make_dir{
	my $dir = shift;
	mkdir $dir unless -d $dir;
}
sub open_dir{
	my $dir = shift;
	return unless $dir;
	mkdir $dir unless -d $dir;
	my $_ = $^O;
	if(/win/i){
		system("start $dir");
	} elsif (/linux/i){
		system("nautilus $dir");
	} else {
		alert_info("Can not open directory:$dir");
	}
}
sub exe_search{
	if($^O =~ /win/i){
		system('start SWR.exe');
	}else{
		system('./SWR &');
	}
}
sub exe_chart{
	if($^O =~ /win/i){
		system('start SWP.exe');
	}else{
		system('./SWP &');
	}
}
sub file_format{
	my $file=shift;
	my $line;
	open FILE, $file;
	while($line = <FILE>){
		last if $line;
	}
	close FILE;
	$line =~ s/^\s+//;
	my $format;
	if($line =~ /^>/){
		$format="fasta";
	}elsif($line=~/^ID/){
		$format="embl";
	}elsif($line=~/^LOCUS/){
		$format="genbank";
	}else{
		$format="other";
	}
	return $format;
}
sub read_file{
	my $file = shift;
	return unless $file;
	open my $FILE, $file;
	my $c;
	sysread($FILE, $c, -s $file);
	close($FILE);
	return \$c;
}

sub mapping_file{
	my $file = shift;
	my $format = file_format($file);
	run_status("Mapping file: $file");
	my $content = read_file($file);
	if($format eq 'fasta'){
		$$content =~ s/^(\s*>.*)//;
	}elsif($format eq 'genbank'){
		$$content =~ s/(.*ORIGIN)//s;
	}elsif($format eq 'embl'){
		$$content =~ s/(.*;)//s;
	}
	$$content =~ s/[\d\s\/]//g;
	return $content;
}
sub purify_seq{
	my ($seq, $format, $name) = @_;
	if($format eq 'fasta'){
		$$seq =~ s/(.*)//;
		$name = $1;
	}elsif($format eq 'genbank'){
		$$seq =~ /ACCESSION\s+(\w+)/;
		$name = $1;
		$$seq =~ s/(.*ORIGIN)//s;
	}elsif($format eq 'embl'){
		$$seq =~ /AC\s+(\w+)/;
		$name = $1;
		$$seq =~ s/(.*;)//s;
	}
	$$seq =~ s/[\d\s\/>]//g;
	return $name;
}

sub insert_tree{
    my ($tree, $file) = @_;
	return if $file_tree->exists($file);
    my $size = -s $file;
    $size = count_file_size($size);
    my $name = basename $file;
	my $val = [$name, $size, 'waiting'];
    my $id = $tree->insert("", "end", -id => $file, -values => $val);
    $tree->see($id);
	run_status("Add file $file");
	$file_num++;
}

sub add_files{
    my $filestr = choose_file();
    return unless $filestr;
	foreach my $file (Tkx::SplitList($filestr)){
		insert_tree($file_tree, $file);
	}
	Tkx::update();
}
sub add_folder{
    my $folder = choose_dir();
    return unless $folder;
	opendir(DIR, $folder)
		or alert_info("Can not open directory:$!");
	$folder = add_path_line($folder);
	while( defined(my $file = readdir DIR)){
		next if -d "$folder$file";
		insert_tree($file_tree, "$folder$file");
	}
	closedir(DIR);
}
sub drag_file{
	my $filestr = shift;
	return unless $filestr;
	foreach my $file (Tkx::SplitList($filestr)){
		insert_tree($file_tree, $file);
	}
}
sub add_path_line{
	my $path = shift;
	unless($path =~ /.*(\/|\\)$/){
		$path .= '/';
	}
	return $path;
}

sub del_tree_item{
    my $id = $file_tree->selection();
    $file_tree->delete($id);
	my @counts = Tkx::SplitList($id);
	$file_num -= scalar(@counts);
	Tkx::update();
}
sub clean_tree{
	my $ids = $file_tree->children("");
    $file_tree->delete($ids);
    $file_num = 0;
    Tkx::update();
}
sub about{
	Tkx::tk___messageBox(
		-title => "About MSDB",
		-message => "MSDB is a small, simple application specially designed to offer\nyou a graphical user interface for finding microsatellite markers\nfrom gnomic sequence.\n\nVersion: 2.4.2\nAuthor: Lianming Du\nMail: adu220\@126.com\nHomepage: http://msdb.biosv.com/\nLast Updated: 2012-12-15",
	);
}
sub timer{
	repeat(\&times);
	sub times{
		$paras{s}++;
		if($paras{s}==60){
			$paras{m}++;
			$paras{s}=0;
		}
		if($paras{m}==60){
			$paras{h}++;
			$paras{m}=0;
		}
		$times=sprintf("%02d:%02d:%02d",$paras{h},$paras{m},$paras{s});
		Tkx::update();
	}
}
sub repeat{
	my $sub = shift;
	my $repeater;
	$repeater = sub {
		$sub->(@_);
		Tkx::after($paras{time_flag}, $repeater);
	};
	Tkx::after($paras{time_flag}, $repeater);
}
sub processing{
	my $current = shift;
	$total_pro_bar = eval{($paras{process_file}+$current)/$file_num*0.9};
	$total_progress = sprintf("%.f%%", $total_pro_bar*100);
	Tkx::update();
}

sub processing_last{
	my $now = shift;
	$total_pro_bar += $now;
	$total_progress = sprintf("%.f%%", $total_pro_bar*100);
	Tkx::update();
}
sub processing_file{
	my $file = shift;
	$file_num_info = "Processing file: $file";
	Tkx::update();
}
# find repeat sequence from files
# some finding functions

sub create_repeat_unite{
    my ($n) = @_;
    my @base = qw/A T G C/;
    return @base if($n == 1);
    my @r_return = create_repeat_unite($n-1);
    my @array;
    foreach my $ch (@base){
      foreach my $re (@r_return){
        push(@array, "$ch$re");
      }
    }
    return @array;
}
sub create_no_same_unites{
    my $no = shift;
    my @unite = create_repeat_unite($no);
	return @unite if $no == 1;
	@unite = grep { !/(A+){$no}|(T+){$no}|(G+){$no}|(C+){$no}/ } @unite;
	if($no % 2 == 0){
		for(my $i = 4; $i <= $no; $i += 2){
		    my @temp = create_repeat_unite($i/2);
			foreach my $unite (@temp){
				@unite = grep {!/($unite){2}/} @unite;
			}
		}
	}
	my @motifs;
	while(@unite){
		my $motif = shift @unite;
		next unless $motif;
		my $ssr = $motif x 20;
		my $i=0;
		foreach (@unite){
			my $ssr1 = $_ x 10;
			if($ssr =~ /$ssr1/){
				$unite[$i]="";
			}
			$i++;
		}
		push @motifs, $motif;
	}
	return @motifs;
}
sub alert_info{
    my ($mes, $p) = @_;
    Tkx::tk___messageBox(-type => "ok", -message => $mes, -icon => "error", -title => "ERROR") if !$p;
	Tkx::tk___messageBox(-type => "ok", -parent => $p, -message => $mes, -icon => "error", -title => "ERROR") if $p;
    Tkx::MainLoop;
}

sub check_paras{
    run_status("Check the setting of parameters");
	alert_info("Please add files!") if !$file_num;
	alert_info("Please seclect output path!") if !$outpath;
	make_dir($outpath);
	if($action == 1){
		if($repeatunite ==2){
			alert_info("Please input repeat unite!") if !$input_repeat_unite;
		}elsif($repeatunite == 3){
			if($paras{motif_flag} == 1){
				alert_info("Please input minimum repeats string!") unless $paras{repeat_stream};
			}else{
				alert_info("Please input minimum microsatellite length!") unless $paras{repeat_length};
			}
		}
		if($repeat_no_type == 2){
			alert_info("Please input minimum repeats!") if !$min_repeat_num;
			alert_info("Please input maximum repeats!") if !$max_repeats;
		} elsif ($repeat_no_type == 0){
			alert_info("Please input minimum repeats!") if !$min_repeat_num;
		} else {
			alert_info("Please input repeats number!") if !$min_repeat_num;
		}
		alert_info("Please input the flanking sequence length!") if !$end_base_num;
	} else {
		if($paras{motif_flag} == 1){
			alert_info("Please input minimum repeats string!") unless $paras{repeat_stream};
		}else{
			alert_info("Please input minimum microsatellite length!") unless $paras{repeat_length};
		}
		alert_info("Please input maximum distance!") unless $paras{distance};
	}
}
sub count_file_size{
    my $s = shift;
	return unless $s;
	$s = sprintf("%dKB", ceil($s/1024));
	return $s;
}
sub run_status{ 
    $run_progress = shift;
    Tkx::update();
}



#################################################################################
#functions for searching microsatellite
#################################################################################

sub get_ssr_by_min{
	my ($filename, $seq, $len, $flank, $min) = @_;
	my $m_min = $min - 1;
	my $seq_len = length($$seq);
	while($$seq =~ /(([ATGC]{1,6}?)\2{$m_min,})/gio){
		next if length($2) != $len;
		my %ssr; # save finded ssr information
		$ssr{uid} = ++$paras{uid};
		$ssr{motif} = uc($2);
		$ssr{length} = length($1);
		$ssr{repeats} = $ssr{length}/$len;
		$ssr{seq} = "($ssr{motif})$ssr{repeats}";
		$ssr{end} = pos($$seq); # end locus
		$ssr{start} = $ssr{end} - $ssr{length} + 1; #start locus
		my $start = $ssr{start} - $flank - 1; #starting site for intercept
		if($start < 0){
			$ssr{left}=substr($$seq, 0, $ssr{start}-1);
		} else {
			$ssr{left}=substr($$seq, $start, $flank);
		}
		$ssr{right}=substr($$seq, $ssr{end}, $flank);
		$ssr{source}=$filename;
		add_hash_to_db(\%ssr, 'ssr');
		run_status("Find SSRs: $paras{uid}  Motif: $ssr{motif}");
		$paras{counts}++;
		$paras{t_ssr_len} += $ssr{length};
	}
}
sub get_ssr_by_interval{
	my ($filename, $seq, $len, $flank, $min, $max) = @_;
	my $m_min=$min-1;
	my $seq_len = length($$seq);
	while($$seq =~ /(([AGCT]{1,6}?)\2{$m_min,}/gio){
		next if length($2) != $len;
		my %ssr;
		$ssr{length} = length($1);
		$ssr{repeats} = $ssr{length}/$len;
		next if $ssr{repeats} > $max;
		$ssr{uid} = ++$paras{uid};
		$ssr{motif} = uc($2);
		$ssr{seq} = "($ssr{motif})$ssr{repeats}";
		$ssr{end} = pos($$seq);
		$ssr{start} = $ssr{end} - $ssr{length} + 1;
		my $start = $ssr{start} - $flank - 1;
		if($start < 0){
			$ssr{left}=substr($$seq, 0, $ssr{start}-1);
		} else {
			$ssr{left}=substr($$seq, $start, $flank);
		}
		$ssr{right}=substr($$seq, $ssr{end}, $flank);
		$ssr{source}=$filename;
		add_hash_to_db(\%ssr, 'ssr');
		run_status("Find SSRs: $paras{uid}  Motif: $ssr{motif}");
		$paras{counts}++;
		$paras{t_ssr_len} += $ssr{length};
	}
}
sub get_ssr_by_specify{
	my ($filename, $seq, $len, $flank, $repeats) = @_;
	my $m_min = $repeats - 1;
	my $seq_len = length($$seq);
	while($$seq =~ /(([ATGC]{1,6})\2{$m_min,})/gio){
		next if length($2) != $len;
		my %ssr=();
		$ssr{length} = length($1);
		$ssr{repeats} = $ssr{length}/$len;
		next if $ssr{repeats} != $repeats;
		$ssr{uid} = ++$paras{uid};
		$ssr{motif}=uc($2);
		$ssr{seq} = "($ssr{motif})$ssr{repeats}";
		$ssr{end} = pos($$seq);
		$ssr{start} = $ssr{end} - $ssr{length} + 1;
		my $start = $ssr{start} - $flank - 1;
		if($start < 0){
			$ssr{left}=substr($$seq, 0, $ssr{start}-1);
		} else {
			$ssr{left}=substr($$seq, $start, $flank);
		}
		$ssr{right}=substr($$seq, $ssr{end}, $flank);
		$ssr{source}=$filename;
		add_hash_to_db(\%ssr, 'ssr');
		run_status("Find SSRs: $paras{uid}  Motif: $ssr{motif}");
		$paras{counts}++;
		$paras{t_ssr_len} += $ssr{length};
	}
}
sub get_ssr_by_custom{
	my ($filename, $seq, $unite, $flank, $flag,$min, $max) = @_;
	$unite=~ s/^\s+|\s+$//g;
	my @motifs = split /\s+|,/, $unite;
	my $motif_num = @motifs;
	$paras{counts}=0;
	$paras{t_ssr_len} = 0;
	my $seq_len = length($$seq);
	while(my $motif = shift @motifs){
		my $m_motif = $motif x $min;
		while($$seq =~ /($m_motif(?:$motif)*)/gio){
			my %ssr=();
			$ssr{length} = length($1);
			$ssr{repeats} = $ssr{length}/length($motif);
			next if $ssr{repeats} < $min;
			if($flag == 1){
				next if $ssr{repeats} != $min;
			}
			if($flag == 2){
				next if $ssr{repeats} > $max;
			}
			$ssr{uid} = ++$paras{uid};
			$ssr{motif}=uc($motif);
			$ssr{seq} = "($ssr{motif})$ssr{repeats}";
			$ssr{end} = pos($$seq);
			$ssr{start} = $ssr{end} - $ssr{length} + 1;
			my $start = $ssr{start} - $flank - 1;
			if($start < 0){
				$ssr{left}=substr($$seq, 0, $ssr{start}-1);
			} else {
				$ssr{left}=substr($$seq, $start, $flank);
			}
			$ssr{right}=substr($$seq, $ssr{end}, $flank);
			$ssr{source}=$filename;
			add_hash_to_db(\%ssr, 'ssr');
			run_status("Find SSRs: $paras{uid}  Motif: $ssr{motif}");
			$paras{counts}++;
			$paras{t_ssr_len} += $ssr{length};
		}
	}
}
sub get_ssr_by_str{
	my ($filename, $seq, $flank, $repeats)=@_;
	my @min;
	if($repeats =~ /-/){
		@min = split /-/, $repeats;
	}else{
		for(my $i = 1; $i <=6; $i++){
			$min[$i-1]=$repeats/$i;
		}
	}	
	my $seq_len = length($$seq);
	my $m_min = $min[5]-1;
	$paras{counts} = 0;
	$paras{t_ssr_len} = 0;
	while($$seq =~ /(([ATGC]{1,6}?)\2{$m_min,})/gio){
		my %ssr=();
		$ssr{motif} = $2;
		my $len = length($2);
		$ssr{length} = length($1);
		$ssr{repeats}=$ssr{length}/$len;
		if($ssr{repeats} < $min[$len-1]){
			next;
		}
		$ssr{motif}=uc($ssr{motif});
		$ssr{seq} = "($ssr{motif})$ssr{repeats}";
		$ssr{uid} = ++$paras{uid};
		$ssr{end} = pos($$seq);
		$ssr{start} = $ssr{end} - $ssr{length} + 1;
		my $start = $ssr{start} - $flank - 1;
		if($start < 0){
			$ssr{left}=substr($$seq, 0, $ssr{start}-1);
		} else {
			$ssr{left}=substr($$seq, $start, $flank);
		}
		$ssr{right}=substr($$seq, $ssr{end}, $flank);
		$ssr{source}=$filename;
		add_hash_to_db(\%ssr, 'ssr');
		run_status("Find SSRs: $paras{uid}  Motif: $ssr{motif}");
		$paras{counts}++;
		$paras{t_ssr_len} += $ssr{length};
	}
}
sub get_comp_inter_ssr{
	my ($filename, $seq, $flank, $repeats, $distance)=@_;
	my @min;
	if($repeats =~ /-/){
		@min = split /-/, $repeats;
	}else{
		for(my $i = 1; $i <=6; $i++){
			$min[$i-1]=$repeats/$i;
		}
	}
	my %temp;
	my %ssr;
	my %ssr1;
	my $seq_len = length($$seq);
	my $m_min = $min[5]-1;
	$paras{counts} = 0;
	$paras{t_ssr_len} = 0;
	while($$seq =~ /(([ATGC]{1,6}?)\2{$m_min,})/gio){
		$temp{motif}=uc($2);
		my $len=length($2);
		$temp{length}=length($1);
		$temp{repeats}=$temp{length}/$len;
		next if $temp{repeats} < $min[$len-1];
		$temp{end}=pos($$seq);
		$temp{complexity} = 1;
		$temp{start}=$temp{end}-$temp{length} + 1;
		$temp{seq} = "($temp{motif})$temp{repeats}";
		%ssr = %temp unless $ssr{start};
		if(%ssr1&&%temp){
			my $space = $temp{start}-$ssr1{end} - 1;
			if($space <= $distance){
				$ssr{complexity}++;
				my $gap_seq;
				if($space > 0){
					$gap_seq=substr($$seq, $ssr1{end}, $space);
				}
				$ssr{motif} .= '-'.$temp{motif};
				$ssr{seq} .= $gap_seq ? "-".$gap_seq."-"."($temp{motif})$temp{repeats}" : "-"."($temp{motif})$temp{repeats}";
				$ssr{length} += $temp{length} + $space;
				$ssr{repeats} += $temp{repeats};
				$ssr{end}=$temp{end};
			}else{
				$ssr{uid} = ++$paras{uid};
				$ssr{motif} = uc($ssr{motif});
				my $start = $ssr{start} - $flank -1;
				if($start < 0){
					$ssr{left}=substr($$seq, 0, $ssr{start}-1);
				} else {
					$ssr{left}=substr($$seq, $start, $flank);
				}
				$ssr{right} = substr($$seq, $ssr{end}, $flank);
				$ssr{source} = $filename;
				($ssr{motif}, $ssr{type}, $ssr{complexity}) = ssr_classify($ssr{seq});
				add_hash_to_db(\%ssr, 'ssr');
				%ssr=();
				%ssr = %temp;
				$paras{counts}++;
				$paras{t_ssr_len} += $ssr{length};
			}
		}
		my $now_site = $ssr{end}/$seq_len;
		run_status("Find SSRs: $paras{uid}");
		%ssr1=();
		%ssr1=%temp;
		%temp=();
	}
	return unless %ssr;
	$ssr{uid} = ++$paras{uid};
	my $start = $ssr{start} - $flank - 1; #starting site for intercept
	if($start < 0){
		$ssr{left}=substr($$seq, 0, $ssr{start}-1);
	} else {
		$ssr{left}=substr($$seq, $start, $flank);
	}
	$ssr{motif} = uc($ssr{motif});
	$ssr{right}=substr($$seq, $ssr{end}, $flank);
	$ssr{source}=$filename;
	($ssr{motif}, $ssr{type}, $ssr{complexity}) = ssr_classify($ssr{seq});
	add_hash_to_db(\%ssr, 'ssr');
	$paras{counts}++;
	$paras{t_ssr_len} += $ssr{length};
}
sub ssr_classify{
	my $seq = shift;
	my @motifs;
	my $gap = 0;
	foreach (split /-/, $seq){
		if(/^\(([atgc]+)\)\d+$/i){
			push @motifs, $1;
		}elsif(/^[atgc]+$/i){
			$gap++;
		}
	}
	my $complexity = scalar(@motifs);
	my %count;
	my @diff = grep { ++$count{$_} < 2 } @motifs;
	my $diff = scalar(@diff);
	my ($type, $motif);
	if($diff == 1 && $complexity == 1){
		$type = 'p';
		$motif = shift @motifs;
	}elsif($diff == 1 && $complexity > 1){
		$type = 'ip';
		$motif = shift @motifs;
	}elsif($diff == 2 && $complexity == 2){
		$type = $gap ? 'icd' : 'cd';
		$motif = join "-", @motifs;
	}else{
		$type = $gap ? 'icx' : 'cx';
		$motif = join "-", @motifs;
	}
	return ($motif, $type, $complexity);
}

###################################################
## connect to database.
## add data into database.
###################################################
sub connect_to_db{
	#generate random string for each tasks
	my $MaxLen = 16;
	my @alpha = (0..9, 'a'..'z', 'A'..'Z','_');
	$paras{sqlite_db} = join '', map {$alpha[int rand @alpha]} 0..($MaxLen - 1);
	$paras{sqlite_db} .= '.db';

	#create database
	$paras{dbh}=DBI->connect("dbi:SQLite:dbname=".$paras{sqlite_db},'','',{AutoCommit => 0})
		or alert_info("Can not connect to database. $DBI::errstr");

	#create table ssr
	$paras{dbh}->do("CREATE TABLE ssr(
		uid INTEGER,
		motif TEXT,
		type TEXT,
		complexity NUMERIC,
		repeats NUMERIC,
		length NUMERIC,
		seq TEXT,
		start NUMERIC,
		end NUMERIC,
		left TEXT,
		right TEXT,
		source TEXT
	)");

	#create table file
	$paras{dbh}->do("CREATE TABLE file(
		filename TEXT PRIMARY KEY,
		size INTEGER,
		count INTEGER,
		length INTEGER
	)");

	$paras{dbh}->commit();

	$paras{dbh}->{LongTruncOk}='True';
	$paras{dbh}->{LongReadLen}=1000;
	$paras{dbh}->do("PRAGMA synchronous = OFF");
	$paras{dbh}->do("PRAGMA cache_size = 8000");
}
sub disconnect_to_db{
	$paras{dbh}->commit();
	$paras{dbh}->disconnect;
}
sub add_hash_to_db{
	my ($field_values, $table) = @_;
	my @fields = sort keys %$field_values;
	my @values = @{$field_values}{@fields};
	my $sql=sprintf ("insert into %s (%s) values (%s)", $table,join(',', @fields), join(',', ("?")x@fields));
	my $sth=$paras{dbh}->prepare($sql);
	$sth->execute(@values);
}
sub delete_db_list{
	my $sql="DELETE FROM ssr";
	my $sth=$paras{dbh}->prepare($sql);
	$sth->execute;
}

sub get_ssr_locus{
	my ($nutide, $repeater, $unite_type, $flank, $repeat_type, $min, $max) = @_;
	my @unites = ();
	my $file = get_first_item();
	return unless $file;
	if($unite_type == 2){
		do{
			set_item_status($file, 'processing');
			my $fname = basename($file, @extensions);
			processing_file($fname);
			my $format = file_format($file);
			local $/;
			if($format eq 'fasta'){
				$/ = '>';
			}else{
				$/ = '//';
			}
			open my $fh, $file;
			while(my $sequence = <$fh>){
				next if $sequence =~ /^\s*>|^\s+$/;
				$fname = purify_seq(\$sequence, $format, $fname);
				get_ssr_by_custom($fname, \$sequence, $repeater, $flank, $repeat_type, $min, $max);
				my %file = (
					filename => $fname,
					size => length($sequence),
					count => $paras{counts},
					length => $paras{t_ssr_len},
				);
				add_hash_to_db(\%file, "file");
				undef $sequence;
			}
			close $fh;
			$paras{process_file}++;
			set_item_status($file, 'complete');
			Tkx::update();
		}while($file = $file_tree->next($file));
		return;
	}
	if($unite_type == 3){
		if($paras{motif_flag} == 1){
			$min = $paras{repeat_stream};
		}else{
			$min = $paras{repeat_length};
		}
		do{
			set_item_status($file, 'processing');
			my $fname = basename($file, @extensions);
			processing_file($fname);
			my $format = file_format($file);
			local $/;
			if($format eq 'fasta'){
				$/ = '>';
			}else{
				$/ = '//';
			}
			open my $fh, $file;	
			while(my $sequence = <$fh>){
				next if $sequence =~ /^\s*>|^\s+$/;
				$fname = purify_seq(\$sequence, $format, $fname);
				get_ssr_by_str($fname, \$sequence, $flank, $min);
				my %file = (
					filename => $fname,
					size => length($sequence),
					count => $paras{counts},
					length => $paras{t_ssr_len},
				);
				add_hash_to_db(\%file, "file");
				undef $sequence;
			}
			close $fh;
			$paras{process_file}++;
			set_item_status($file, 'complete');
			Tkx::update();
			
		}while($file = $file_tree->next($file));
		
		return;
	}
	my @callbacks = (\&get_ssr_by_min, \&get_ssr_by_specify, \&get_ssr_by_interval);
	do{
		set_item_status($file, 'processing');
		my $fname = basename($file, @extensions);
		processing_file($fname);
		$paras{counts}=0;
		$paras{t_ssr_len} = 0;
		my $format = file_format($file);
		local $/;
		if($format eq 'fasta'){
			$/ = '>';
		}else{
			$/ = '//';
		}
		open my $fh, $file;	
		while(my $sequence = <$fh>){
			next if $sequence =~ /^\s*>|^\s+$/;
			$fname = purify_seq(\$sequence, $format, $fname);
			$callbacks[$repeat_type]->($fname, \$sequence, $nutide, $flank, $min, $max);
			my %file = (
				filename => $fname,
				size => length($sequence),
				count => $paras{counts},
				length => $paras{t_ssr_len},
			);
			add_hash_to_db(\%file, "file");
			undef $sequence;
		}
		close $fh;
		$paras{process_file}++;
		set_item_status($file, 'complete');
		Tkx::update();
		
	}while($file = $file_tree->next($file));
	
}

sub ssr_search_mode{
	get_ssr_locus($base_num, $input_repeat_unite, $repeatunite, $end_base_num, $repeat_no_type, $min_repeat_num, $max_repeats);
}
sub ssr_compinter_mode{
	my $file = get_first_item();
	return unless $file;
	do{
		set_item_status($file, 'processing');
		my $fname = basename($file, @extensions);
		processing_file($fname);
		my $repeater;
		if($paras{motif_flag} == 1){
			$repeater = $paras{repeat_stream};
		}else{
			$repeater = $paras{repeat_length};
		}
		my $format = file_format($file);
		local $/;
		if($format eq 'fasta'){
			$/ = '>';
		}else{
			$/ = '//';
		}
		open my $fh, $file;	
		while(my $sequence = <$fh>){
			next if $sequence =~ /^\s*>|^\s+$/;
			$fname = purify_seq(\$sequence, $format, $fname);
			get_comp_inter_ssr($fname, \$sequence, $end_base_num, $repeater, $paras{distance});
			my %file = (
				filename => $fname,
				size => length($sequence),
				count => $paras{counts},
				length => $paras{t_ssr_len},
			);
			add_hash_to_db(\%file, "file");
			undef $sequence;
		}
		close $fh;
		$paras{process_file}++;
		set_item_status($file, 'complete');
		Tkx::update();
		
	}while($file = $file_tree->next($file));
	
}

#######################################################
# output statistics function.
#######################################################
sub stat_motif_length{
	my $file = shift;
	my %counts;
	my $sql = "select length(motif),count(*),sum(length) from ssr";
	$sql .= " where source='$file'" if $file;
	$sql .= " group by length(motif)";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	while(my @row = $sth->fetchrow_array){
		$counts{$row[0]} = "$row[1]-$row[2]";
	}
	return \%counts;
}
sub stat_motif_type{
	my $file = shift;
	my %counts;
	my $sql = "select motif,count(*),sum(length) from ssr";
	$sql .= " where source='$file'" if $file;
	$sql .= " group by motif";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	while(my @row = $sth->fetchrow_array){
		$counts{$row[0]} = "$row[1]-$row[2]";
	}
	return \%counts;
}
sub stat_motif_repeat{
	my $file = shift;
	my %counts;
	my $sql = "select motif,repeats,count(*),sum(length) from ssr";
	$sql .= " where source='$file'" if $file;
	$sql .= " group by motif,repeats";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	while(my @row = $sth->fetchrow_array){
		$counts{$row[0]}{$row[1]} = "$row[2]-$row[3]";
	}
	return \%counts;
}
sub total_file_size{
	my $file = shift;
	my $sql = "select sum(size) from file";
	$sql = "select size from file where filename='$file'" if $file;
	my $size = $paras{dbh}->selectrow_array($sql);
	return $size;
}
sub total_ssr_count{
	my $file = shift;
	my $sql = "select sum(count) from file";
	$sql = "select count from file where filename='$file'" if $file;
	my $count = $paras{dbh}->selectrow_array($sql);
	return $count;
}
sub op_stat_motif_type{
	run_status("output motif type statistics");
	my ($file, $total, $xls, $style)=@_;
	my $mt=$xls->add_worksheet('motif type');
	my $temp = stat_motif_type($file);
	my %temp = %$temp;
	undef %$temp;
	############### delete the similar motif
	my @motifs=sort keys %temp;
	while(@motifs){
		my $motif = shift @motifs;
		next unless $motif;
		my $ssr = $motif x 20;
		my $i=0;
		foreach (@motifs){
			my $ssr1 = $_ x 10;
			if($ssr =~ /$ssr1/){
				my ($c, $l) = split /-/, $temp{$motif};
				my ($tc, $tl) = split /-/, $temp{$motifs[$i]};
				$c += $tc;
				$l += $tl;
				$temp{$motif} = "$c-$l";
				delete $temp{$motifs[$i]};
				$motifs[$i]="";
			}
			$i++;
		}
	}
	undef @motifs;
	################## end
	my $head = ['Motif', 'Motif Length', 'Total Counts', 'Total Length(bp)', 'Average Length(bp)', 'Frequency(loci/Mb)', 'Density(bp/Mb)'];
	$mt->write_row(0, 0, $head, $style);
	my $i=1;
	foreach (sort keys %temp){
		my ($temp_c, $temp_l) = split /-/, $temp{$_};
		my $size = sprintf("%.2f", $temp_c/$total);
		my $lmb = sprintf("%.2f", $temp_l/$total);
		my $avg_len = sprintf("%.2f", $temp_l/$temp_c);
		my $mlen = length($_);
		my @c = ($_, $mlen, $temp_c, $temp_l, $avg_len, $size, $lmb);
		$mt->write_row($i++, 0, \@c, $style);
		Tkx::update();
	}
	undef %temp;
}
sub op_stat_motif_len{
	run_status("output motif length statistics");
	my ($file, $total, $xls, $style) = @_;
	my $ml=$xls->add_worksheet('motif length');
	$ml->set_column('A:A',20);
	my $temp = stat_motif_length($file);
	my %temp = %$temp;
	undef %$temp;
	my @len=qw/mononucleotide dinucleotide trinucleotide tetranucleotide pentanucleotide hexanucleotide/;
	my @head=('Nucleotide', 'Total Counts', 'Total Length(bp)', 'Average Length(bp)', 'Frequency(loci/Mb)', 'Density(bp/Mb)');
	$ml->write_row(0,0,\@head,$style);
	my $i=1;
	foreach (sort keys %temp){
		my ($temp_c, $temp_l) = split /-/, $temp{$_};
		my $size = sprintf("%.2f", $temp_c/$total);
		my $avg_len = sprintf("%.2f", $temp_l/$temp_c);
		my $lmb = sprintf("%.3f", $temp_l/$total);
		my @c = ($len[$_-1], $temp_c, $temp_l, $avg_len, $size, $lmb);
		$ml->write_row($i++, 0, \@c, $style);
		Tkx::update();
	}
	undef %temp;
}
sub op_stat_motif_rep{
	run_status("output motif repeats statistics");
	my ($file, $total, $xls, $style)=@_;
	my $mr=$xls->add_worksheet('motif repeats');
	my $mstyle=$xls->add_format();
	$mstyle->set_align('center');
	$mstyle->set_align('vcenter');
	my $temp=stat_motif_repeat($file);
	my %temp=%$temp;
	undef %$temp;
	my @head=('Motif', 'Repeats', 'Total Counts', 'Total Length(bp)', 'Average Length(bp)', 'Frequency(loci/Mb)', 'Density(bp/Mb)');
	$mr->write_row(0,0,\@head,$style);
	my $i=1;
	my $start = 2;
	foreach my $key1 (sort keys %temp){
		foreach my $key2 (sort {$a <=> $b} keys %{$temp{$key1}}){
			my($temp_count, $temp_len) = split /-/, $temp{$key1}{$key2};
			my $avg_len = sprintf("%.2f", $temp_len/$temp_count);
			my $fre = sprintf("%.2f", $temp_count/$total);
			my $den = sprintf("%.2f", $temp_len/$total);
			my @c = ($key1, $key2, $temp_count, $temp_len, $avg_len, $fre, $den);
			$mr->write_row($i++,0,\@c,$style);
			Tkx::update();
		}
		$mr->merge_range("A$start:A$i", $key1,$mstyle) if $start != $i;
		$start = $i+1;
		Tkx::update();
	}
	undef %temp;
}
sub op_stat_ssr_type{
	run_status("output ssr type statistics");
	my ($file, $total, $xls, $style) = @_;
	my $st=$xls->add_worksheet('ssr type');
	my $head = ['Type', 'Total Counts', 'Total Length(bp)', 'Average Length(bp)', 'Frequency(loci/Mb)', 'Density(bp/Mb)'];
	$st->write_row(0, 0, $head, $style);
	my $sql = "SELECT type,count(*),sum(length) FROM ssr";
	$sql .= " WHERE source='$file'" if $file;
	$sql .= " GROUP BY type";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	my $i = 1;
	while(my @row = $sth->fetchrow_array){
		push @row, sprintf("%.2f", $row[2]/$row[1]);
		push @row, sprintf("%.2f", $row[1]/$total);
		push @row, sprintf("%.2f", $row[2]/$total);
		$st->write_row($i++, 0, \@row, $style);
	}
}
sub op_stat_file_info{
	my ($xls, $style) = @_;
	my $st = $xls->add_worksheet('file info');
	my @head=('Sequence Name', 'Sequence Length(bp)', 'Total SSR Counts', 'Total SSR Length(bp)', 'Average Length(bp)','Frequency(loci/Mb)', 'Density(bp/Mb)');
	$st->write_row(0,0,\@head, $style);
	my $sql = "select * from file";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	my $i = 1;
	while(my @row = $sth->fetchrow_array){
		push @row, $row[2] ? sprintf("%.2f", $row[3]/$row[2]) : 0;
		push @row, $row[1] ? sprintf("%.2f", $row[2]/$row[1]*1000000) : 0;
		push @row, $row[1] ? sprintf("%.2f", $row[3]/$row[1]*1000000) : 0;
		$st->write_row($i++, 0, \@row, $style);
	}
}
sub get_time_str{
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
	$mon++;
	$year+=1900;
	my $time = "$year-$mon-$mday"." "."$hour-$min-$sec";
	return $time;
}
sub output_to_excel{
	my ($opdir, $file) = @_;
	$opdir = add_path_line($opdir);
	my $total= total_file_size($file)/1000000;
	my $time = get_time_str();
	my $excel = $file ? $opdir.$file."_statistics_$time.xls" : $opdir."statistics_$time.xls";
	my $xls = Spreadsheet::WriteExcel->new($excel);
	$xls->compatibility_mode();
	my $style = $xls->add_format();
	$style->set_align('center');
	$style->set_align('vcenter');
	op_stat_file_info($xls, $style) unless $file;
	if($action == 1){
		op_stat_motif_len($file, $total, $xls, $style) if $paras{length_table};
		op_stat_motif_type($file, $total, $xls, $style) if $paras{type_table};
		op_stat_motif_rep($file, $total, $xls, $style) if $paras{repeats_table};
	}else{
		op_stat_ssr_type($file, $total, $xls, $style) if $paras{ssrtype_table};
		imperfect_ssr_stat($file, $total, $xls, $style, 'pure') if $paras{pure_table};
		imperfect_ssr_stat($file, $total, $xls, $style, 'compound') if $paras{cpd_table};
		imperfect_ssr_stat($file, $total, $xls, $style, 'complex') if $paras{cpx_table};
	}
	$xls->close();
}
sub imperfect_ssr_stat{
	my($file, $total, $xls, $style, $type) = @_;
	my $worksheet = $xls->add_worksheet("$type ssr");
	my $head=['Motif', 'Total Counts', 'Total Length(bp)', 'Average Length(bp)', 'Frequency(loci/Mb)', 'Density(bp/Mb)'];
	$worksheet->write_row(0,0,$head, $style);
	my $sql = "SELECT motif,count(*),sum(length) FROM ssr WHERE";
	if($type eq 'pure'){
		$sql .= " (type='p' OR type='ip')";
	}elsif($type eq 'compound'){
		$sql .= " (type='cd' OR type='icd')";
	}else{
		$sql .= " (type='cx' OR type='icx')";
	}
	$sql .= " AND source='$file'" if $file;
	$sql .= " GROUP BY motif";
	my $sth = $paras{dbh}->prepare($sql);
	$sth->execute;
	my $i = 1;
	while(my @row = $sth->fetchrow_array){
		push @row, sprintf("%.2f", $row[2]/$row[1]);
		push @row, sprintf("%.2f", $row[1]/$total);
		push @row, sprintf("%.2f", $row[2]/$total);
		$worksheet->write_row($i++, 0, \@row, $style);
	}
}
sub output_statistics{
	if($paras{statway} eq "file"){
		my $file = get_first_item();
		return unless $file;
		do{
			my $fname = basename($file, @extensions);
			output_to_excel($outpath, $fname);
			Tkx::update();
		}while($file = $file_tree->next($file));
	}
	output_to_excel($outpath);
}

sub output_mdb_file{
	my $time = get_time_str();
	rename $paras{sqlite_db}, "database-$time.db";
	move("database-$time.db", $outpath);
}
sub seq_segment{
	my ($file, $dir, $p) = @_;
	alert_info("Please select input file!", $p) if !$file;
	alert_info("Please select output directory!", $p) if !$dir;
	$paras{sw_probar} = 0;
	Tkx::update();
	$dir = add_path_line($dir);
	my $format = file_format($file);
	my $size = -s $file;
	my $fn = basename($file, @extensions);
	my $count = 1;
	my $temp_size = 0;
	if($format eq 'fasta'){
		local $/ = '>';
		open FILE, $file
			or alert_info("Can not open $file:$!", $p);
		while(<FILE>){
			next if /^\s*>/;
			s/>//;
			my $opfile = $dir.$fn.'_'.$count.'.txt';
			open OP, '>', $opfile;
			print OP ">".$_;
			close OP;
			$count++;
			$temp_size += -s $opfile;
			$paras{sw_probar} = $temp_size/$size;
			Tkx::update();
		}
		$paras{sw_probar} = 1;
		close FILE;
	}elsif($format eq 'genbank' || $format eq 'embl'){
		local $/ = '//';
		open FILE, $file
			or alert_info("Can not open $file:$!", $p);
		while(<FILE>){
			my $opfile = $dir.$fn.'_'.$count.'.txt';
			open OP, '>', $opfile;
			print OP $_;
			close OP;
			$count++;
			$temp_size += -s $opfile;
			$paras{sw_probar} = $temp_size/$size;
			Tkx::update();
		}
		$paras{sw_probar} = 1;
		close FILE;
	}else{
		alert_info("Input file is not a fasta, genbank or embl sequence file!", $p);
	}
}

sub get_first_item{
	my $id = $file_tree->insert('',0);
	my $next_id = $file_tree->next($id);
	$file_tree->delete($id);
	return $next_id;
}
sub set_item_status{
	my ($item, $val) = @_;
	$file_tree->set($item, 'state', $val);
	$file_tree->see($item);
}

sub test{
	#print $file_tree->index(0);
	#return;
	my $next_id = get_first_item();
	my $i = 0;
	do{
		print $i,"\t";
		print $next_id;
		print "\n";
		$i++;
	}while($next_id = $file_tree->next($next_id));
	
}
#####################Main Function#####################
sub main_func{
	check_paras();
	$pro_gress_bar->start;
	$times="00:00:00";
	$paras{m}=$paras{h}=$paras{s}=0;
	$paras{time_flag}=1000;
	timer();
	$paras{process_file}=0;
	$file_num_info="";
	$paras{'startime'} = localtime;
	$paras{uid}=0;
	$widget{start_bn}->state("disabled");
	$widget{m_action}->entryconfigure("Start Search", -state => "disabled");
	connect_to_db();
	my $mode = shift;
	if($mode == 1){
		ssr_search_mode();
	} else {
		ssr_compinter_mode();
	}
	output_statistics();
	disconnect_to_db();
	output_mdb_file();
	#delete_db_list();
	$paras{time_flag} = "cancel";
    run_status('Tasks completed!');
	$widget{start_bn}->state("!disabled");
	$widget{m_action}->entryconfigure("Start Search", -state => "normal");
	$paras{'endtime'} = localtime;
	$pro_gress_bar->stop;
    Tkx::tk___messageBox(-message => "Tasks completed!\nStart: $paras{'startime'}\nEnd: $paras{'endtime'}", -title => "Completed");
}