# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # get change state data
        my $ChangeStateDataRef = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
            Class => 'ITSM::ChangeManagement::Change::State',
            Name  => 'requested',
        );

        # get change object
        my $ChangeObject = $Kernel::OM->Get('Kernel::System::ITSMChange');

        # create test change
        my $ChangeTitleRandom = 'ITSMChange Requested ' . $Helper->GetRandomID();
        my $ChangeID          = $ChangeObject->ChangeAdd(
            ChangeTitle   => $ChangeTitleRandom,
            Description   => 'Selenium Test Description',
            Justification => 'Seleniun Test Justification',
            ChangeStateID => $ChangeStateDataRef->{ItemID},
            UserID        => 1,
        );
        $Self->True(
            $ChangeID,
            "$ChangeTitleRandom - created",
        );

        # get work order object
        my $WorkOrderObject = $Kernel::OM->Get('Kernel::System::ITSMChange::ITSMWorkOrder');

        # create test work order
        my $WorkOrderTitleRandom = 'Selenium Work Order ' . $Helper->GetRandomID();
        my $WorkOrderID          = $WorkOrderObject->WorkOrderAdd(
            ChangeID       => $ChangeID,
            WorkOrderTitle => $WorkOrderTitleRandom,
            Instruction    => 'Selenium Test Work Order',
            PlannedEffort  => 10,
            UserID         => 1,
        );
        $Self->True(
            $ChangeID,
            "$WorkOrderTitleRandom - created",
        );

        # get ticket object
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

        # create test ticket
        my $TicketNumber = $TicketObject->TicketCreateNumber();
        my $TicketID     = $TicketObject->TicketCreate(
            TN           => $TicketNumber,
            Title        => 'Selenium Test Ticket',
            Queue        => 'Raw',
            Lock         => 'unlock',
            Priority     => '3 normal',
            State        => 'open',
            CustomerID   => 'Test Selenium Customer',
            CustomerUser => 'Test Selenium Customer',
            OwnerID      => 1,
            UserID       => 1,
        );
        $Self->True(
            $TicketID,
            "Ticket ID $TicketID - created",
        );

        # create and log in test user
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => [ 'admin', 'users', 'itsm-change', 'itsm-change-builder', 'itsm-change-manager' ]
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AgentITSMWorkOrderZoom of created test work order
        $Selenium->get("${ScriptAlias}index.pl?Action=AgentITSMWorkOrderZoom;WorkOrderID=$WorkOrderID");

        # click on 'Link' and switch screens
        $Selenium->find_element("//a[contains(\@href, \'Action=AgentLinkObject;SourceObject=ITSMWorkOrder' )]")
            ->click();

        my $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[1] );

        # select test created ticket to link with test created work order
        $Selenium->execute_script(
            "\$('#TargetIdentifier').val('Ticket').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element("//input[\@name='SEARCH::TicketNumber']")->send_keys($TicketNumber);
        $Selenium->find_element("//button[\@value='Search'][\@type='submit']")->click();
        $Selenium->WaitFor( JavaScript => "return \$('input#LinkTargetKeys').length" );

        $Selenium->find_element("//input[\@id='LinkTargetKeys']")->click();
        $Selenium->find_element("//button[\@id='AddLinks'][\@type='submit']")->click();
        $Selenium->find_element( "#LinkAddCloseLink", 'css' )->click();

        $Selenium->switch_to_window( $Handles->[0] );

        # verify test work order is linked with test ticket
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumber ) > -1,
            "Test ticket number $TicketNumber - found",
        );

        # click on 'Link' and switch screens
        $Selenium->find_element("//a[contains(\@href, \'Action=AgentLinkObject;SourceObject=ITSMWorkOrder' )]")
            ->click();

        $Handles = $Selenium->get_window_handles();
        $Selenium->switch_to_window( $Handles->[1] );

        # delete link relation
        $Selenium->find_element("//a[contains(\@href, \'Subaction=LinkDelete' )]")->click();
        $Selenium->find_element("//input[\@id='LinkDeleteIdentifier']")->click();
        $Selenium->find_element("//button[\@type='submit']")->click();

        $Selenium->find_element("//a[contains(\@href, \'Action=AgentLinkObject;Subaction=Close' )]")->click();
        $Selenium->switch_to_window( $Handles->[0] );

        # verify that link has been removed
        $Self->True(
            index( $Selenium->get_page_source(), $TicketNumber ) == -1,
            "Test ticket number $TicketNumber - found",
        );

        # delete test created work order
        my $Success = $WorkOrderObject->WorkOrderDelete(
            WorkOrderID => $WorkOrderID,
            UserID      => 1,
        );
        $Self->True(
            $Success,
            "$WorkOrderTitleRandom - deleted",
        );

        # delete test created change
        $Success = $ChangeObject->ChangeDelete(
            ChangeID => $ChangeID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "$ChangeTitleRandom - deleted",
        );

        # delete test created ticket
        $Success = $TicketObject->TicketDelete(
            TicketID => $TicketID,
            UserID   => 1,
        );
        $Self->True(
            $Success,
            "Ticket ID $TicketID - deleted",
        );

        # make sure cache is correct
        $Kernel::OM->Get('Kernel::System::Cache')->CleanUp( Type => 'ITSMChange*' );
    }
);

1;
