use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Reuters::SSL',
    'VERSION_FROM' => 'SSL.pm', # finds $VERSION
    'LIBS'	=> ['-lssl -lsocket -lnsl'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/testusers/luxnet/perl/ssl/ssl/include',     # e.g., '-I/usr/include/other' 
    'CC'	=> '/opt/soft/SUNWspro/bin/cc',
    'LD'	=> '/opt/soft/SUNWspro/bin/cc',
);
