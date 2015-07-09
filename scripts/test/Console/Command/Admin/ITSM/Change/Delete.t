# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## no critic (Modules::RequireExplicitPackage)
use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $CommandObject = $Kernel::OM->Get('Kernel::System::Console::Command::Admin::ITSM::Change::Delete');

# check command without option
my $ExitCode = $CommandObject->Execute();

$Self->Is(
    $ExitCode,
    1,
    "Admin::ITSM::Change::Check - No options",
);

#check command with option --all and argument --accept n ( cancel command )
$ExitCode = $CommandObject->Execute( '--all', 'n' );

$Self->Is(
    $ExitCode,
    0,
    "Option '--all' n",
);

1;
