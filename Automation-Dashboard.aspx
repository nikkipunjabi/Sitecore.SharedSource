<%@ Page Language="C#" AutoEventWireup="true"  %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>VisitDubai - Automation Tools</title>

    <!-- Bootstrap Core CSS -->
    <link href="bootstrap/css/bootstrap.min.css" rel="stylesheet">

    <!-- Font Awesome CSS -->
    <link href="css/font-awesome.min.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="css/animate.css" rel="stylesheet">

    <!-- Custom CSS -->
    <link href="css/style.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href='http://fonts.googleapis.com/css?family=Lobster' rel='stylesheet' type='text/css'>


    <!-- Template js -->
    <script src="js/jquery-2.1.1.min.js"></script>
    <script src="bootstrap/js/bootstrap.min.js"></script>
    <script src="js/jquery.appear.js"></script>
    <script src="js/contact_me.js"></script>
    <script src="js/jqBootstrapValidation.js"></script>
    <script src="js/modernizr.custom.js"></script>
    <script src="js/script.js"></script>

    <!--[if lt IE 9]>
            <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
            <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
        <![endif]-->

    <script language="CS" runat="server"> 

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            if (Sitecore.Context.User.IsAuthenticated == false)
            {
                Response.Redirect("login.aspx?returnUrl=Automation-Dashboard.aspx");
            }
        }
    </script>

</head>
<body>
    <form id="form1" runat="server">
        <!-- Start Logo Section -->
        <section id="logo-section" class="text-center">
            <div class="container">
                <div class="row">
                    <div class="col-md-12">
                        <div class="logo text-center">
                            <h1>VisitDubai - Automation Tools</h1>
                            <h3 style="color: white">Use these tools with a BIG caution!</h3>
                        </div>
                    </div>
                </div>
            </div>
        </section>
        <!-- End Logo Section -->

        <!-- Start Main Body Section -->
        <div class="mainbody-section text-center">
            <div class="container">
                <div class="row">

                    <div class="col-md-3">

                        <div class="menu-item blue">
                            <a href="bulkupdate.aspx">
                                <i class="fa fa-pencil-square-o"></i>
                                <p>Bulk Update</p>
                            </a>
                        </div>

                        <div class="menu-item light-orange">
                            <a href="bulkdelete.aspx">
                                <i class="fa fa-times"></i>
                                <p>Bulk Delete</p>
                            </a>
                        </div>

                        <div class="menu-item green">
                            <a href="languagereport.aspx">
                                <i class="fa fa-language"></i>
                                <p>Language Report</p>
                            </a>
                        </div>

                    </div>


                    <div class="col-md-3">

                        <div class="menu-item green">
                            <a href="bulkpublish.aspx">
                                <i class="fa fa-globe"></i>
                                <p>Bulk Publish</p>
                            </a>
                        </div>

                        <div class="menu-item color">
                            <a href="fieldcopier.aspx">
                                <i class="fa fa-files-o"></i>
                                <p>Field Copier</p>
                            </a>
                        </div>

                        <div class="menu-item blue">
                            <a href="userreport.aspx">
                                <i class="fa fa-users"></i>
                                <p>User Report</p>
                            </a>
                        </div>

                    </div>

                    <div class="col-md-3">

                        <div class="menu-item light-red">
                            <a href="exportitem.aspx">
                                <i class="fa fa-cloud-download"></i>
                                <p>Export Sitecore Items</p>
                            </a>
                        </div>

                        <div class="menu-item blue">
                            <a href="unlockitem.aspx">
                                <i class="fa  fa-unlock"></i>
                                <p>Bulk Unlock</p>
                            </a>
                        </div>

                        <div class="menu-item light-red">
                            <a href="genericreport.aspx">
                                <i class="fa fa-list-ul"></i>
                                <p>Generic Report</p>
                            </a>
                        </div>

                    </div>
                      <div class="col-md-3">
                        <div class="menu-item color">
                            <a href="pagecount.aspx">
                                <i class="fa fa-cloud-download"></i>
                                <p>Page Count</p>
                            </a>
                        </div>                      

                    </div>
                </div>
            </div>
        </div>
        <!-- End Main Body Section -->
    </form>
</body>
</html>
