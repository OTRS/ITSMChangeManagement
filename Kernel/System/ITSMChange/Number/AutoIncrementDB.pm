# --
# Copyright (C) 2016 Informatyka Boguslawski sp. z o.o. sp.k., http://www.ib.pl/
# Based on AutoIncrement.pm by OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

# Generates change numbers like ID##### (e. g. 1000123).
# Counter is being stored in DB.

package Kernel::System::ITSMChange::Number::AutoIncrementDB;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub ChangeNumberCreate {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
    my $CounterObject = $Kernel::OM->Get('Kernel::System::Counter');

    # get needed config options
    my $SystemID = $ConfigObject->Get('SystemID');
    my $MinSize = $ConfigObject->Get('ITSMChange::NumberGenerator::AutoIncrement::MinCounterSize')
        || 5;

    # define number of maximum loops if created change number exists
    my $MaxRetryNumber        = 16000;
    my $LoopProtectionCounter = 0;

    # try to create a unique change number for up to $MaxRetryNumber times
    while ( $LoopProtectionCounter <= $MaxRetryNumber ) {

        # get next TicketNumber counter value for new ticket
        my $Count = $CounterObject->IncrementAndGet(
            CounterName => 'ITSMChange::ChangeNumber',
            Value => 1,
            UserID => 1,
        );

        # abort if counter value cannot be obtained
        return if !defined $Count;

        # pad change number with leading '0' to length $MinSize (config option)
        my $ChangeNumber = $SystemID . sprintf('%.*u', $MinSize, $Count);

        # lookup if change number exists already
        my $ChangeID = $Self->ChangeLookup(
            ChangeNumber => $ChangeNumber,
        );

        # now we have a new unused change number and return it
        return $ChangeNumber if !$ChangeID;

        # start loop protection mode
        $LoopProtectionCounter++;

        # create new change number again
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "ChangeNumber ($ChangeNumber) exists! Creating a new one.",
        );
    }

    # loop was running too long
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => "LoopProtectionCounter is now $LoopProtectionCounter!"
            . " Stopped ChangeNumberCreate()!",
    );

    return;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
