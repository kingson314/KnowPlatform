<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%--
  - Renders a whole HTML page for displaying item metadata.  Simply includes
  - the relevant item display component in a standard HTML page.
  -
  - Attributes:
  -    display.all - Boolean - if true, display full metadata record
  -    item        - the Item to display
  -    collections - Array of Collections this item appears in.  This must be
  -                  passed in for two reasons: 1) item.getCollections() could
  -                  fail, and we're already committed to JSP display, and
  -                  2) the item might be in the process of being submitted and
  -                  a mapping between the item and collection might not
  -                  appear yet.  If this is omitted, the item display won't
  -                  display any collections.
  -    admin_button - Boolean, show admin 'edit' button
  --%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="org.dspace.content.Collection" %>
<%@ page import="org.dspace.content.Metadatum" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.handle.HandleManager" %>
<%@ page import="org.dspace.license.CreativeCommons" %>
<%@page import="javax.servlet.jsp.jstl.fmt.LocaleSupport"%>
<%@page import="org.dspace.versioning.Version"%>
<%@page import="org.dspace.core.Context"%>
<%@page import="org.dspace.app.webui.util.VersionUtil"%>
<%@page import="org.dspace.app.webui.util.UIUtil"%>
<%@page import="org.dspace.authorize.AuthorizeManager"%>
<%@page import="java.util.List"%>
<%@page import="org.dspace.core.Constants"%>
<%@page import="org.dspace.eperson.EPerson"%>
<%@page import="org.dspace.versioning.VersionHistory"%>
<%
    // Attributes
    Boolean displayAllBoolean = (Boolean) request.getAttribute("display.all");
    boolean displayAll = (displayAllBoolean != null && displayAllBoolean.booleanValue());
    Boolean suggest = (Boolean)request.getAttribute("suggest.enable");
    boolean suggestLink = (suggest == null ? false : suggest.booleanValue());
    Item item = (Item) request.getAttribute("item");
    Collection[] collections = (Collection[]) request.getAttribute("collections");
    Boolean admin_b = (Boolean)request.getAttribute("admin_button");
    boolean admin_button = (admin_b == null ? false : admin_b.booleanValue());
    
    // get the workspace id if one has been passed
    Integer workspace_id = (Integer) request.getAttribute("workspace_id");

    // get the handle if the item has one yet
    String handle = item.getHandle();

    // CC URL & RDF
    String cc_url = CreativeCommons.getLicenseURL(item);
    String cc_rdf = CreativeCommons.getLicenseRDF(item);

    // Full title needs to be put into a string to use as tag argument
    String title = "";
    if (handle == null)
 	{
		title = "Workspace Item";
	}
	else 
	{
		Metadatum[] titleValue = item.getDC("title", null, Item.ANY);
		if (titleValue.length != 0)
		{
			title = titleValue[0].value;
		}
		else
		{
			title = "Item " + handle;
		}
	}
    boolean pmcEnabled = ConfigurationManager.getBooleanProperty("cris","pmc.enabled",false);
    boolean scopusEnabled = ConfigurationManager.getBooleanProperty("cris","ametrics.elsevier.scopus.enabled",false);
    boolean wosEnabled = ConfigurationManager.getBooleanProperty("cris","ametrics.thomsonreuters.wos.enabled",false);
    String doi = item.getMetadata("dc.identifier.doi");
    boolean scholarEnabled = ConfigurationManager.getBooleanProperty("cris","ametrics.google.scholar.enabled",false);
    boolean altMetricEnabled = ConfigurationManager.getBooleanProperty("cris","ametrics.altmetric.enabled",false) && StringUtils.isNotBlank(doi);
    
    Boolean versioningEnabledBool = (Boolean)request.getAttribute("versioning.enabled");
    boolean versioningEnabled = (versioningEnabledBool!=null && versioningEnabledBool.booleanValue());
    Boolean hasVersionButtonBool = (Boolean)request.getAttribute("versioning.hasversionbutton");
    Boolean hasVersionHistoryBool = (Boolean)request.getAttribute("versioning.hasversionhistory");
    boolean hasVersionButton = (hasVersionButtonBool!=null && hasVersionButtonBool.booleanValue());
    boolean hasVersionHistory = (hasVersionHistoryBool!=null && hasVersionHistoryBool.booleanValue());
    
    Boolean newversionavailableBool = (Boolean)request.getAttribute("versioning.newversionavailable");
    boolean newVersionAvailable = (newversionavailableBool!=null && newversionavailableBool.booleanValue());
    Boolean showVersionWorkflowAvailableBool = (Boolean)request.getAttribute("versioning.showversionwfavailable");
    boolean showVersionWorkflowAvailable = (showVersionWorkflowAvailableBool!=null && showVersionWorkflowAvailableBool.booleanValue());
    
    String latestVersionHandle = (String)request.getAttribute("versioning.latestversionhandle");
    String latestVersionURL = (String)request.getAttribute("versioning.latestversionurl");
    
    VersionHistory history = (VersionHistory)request.getAttribute("versioning.history");
    List<Version> historyVersions = (List<Version>)request.getAttribute("versioning.historyversions");
%>

<%@page import="org.dspace.app.webui.servlet.MyDSpaceServlet"%>

<% if(pmcEnabled || scopusEnabled || wosEnabled || scholarEnabled || altMetricEnabled) { %>
<c:set var="dspace.layout.head.last" scope="request">
<% if(altMetricEnabled) { %> 
<script type='text/javascript' src='https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js'></script>
<% } %>
<script type="text/javascript"><!--
var j = jQuery.noConflict();

}

j(document).ready(function() {

	<% if(altMetricEnabled) { %>
	j(function () {
	    j('div.altmetric-embed').on('altmetric:hide ', function () {
	    	j('div.altmetric').hide();
	    });
	});
	<% } %>
});
--></script>
</c:set>
<% } %>

<dspace:layout title="<%= title %>">
    
    <%
        if (admin_button)  // admin edit button
        { %>
        <div class="col-sm-5 col-md-12 col-lg-3" style="float: right;z-index: 2;">
            <div class="panel panel-warning">
            	<div class="panel-heading"><fmt:message key="jsp.admintools"/></div>
            	<div class="panel-body">
                <form method="get" action="<%= request.getContextPath() %>/tools/edit-item">
                    <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                    <%--<input type="submit" name="submit" value="Edit...">--%>
                    <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.general.edit.button"/>" />
                </form>
                <form method="post" action="<%= request.getContextPath() %>/mydspace">
                    <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                    <input type="hidden" name="step" value="<%= MyDSpaceServlet.REQUEST_EXPORT_ARCHIVE %>" />
                    <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.mydspace.request.export.item"/>" />
                </form>
                <form method="post" action="<%= request.getContextPath() %>/mydspace">
                    <input type="hidden" name="item_id" value="<%= item.getID() %>" />
                    <input type="hidden" name="step" value="<%= MyDSpaceServlet.REQUEST_MIGRATE_ARCHIVE %>" />
                    <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.mydspace.request.export.migrateitem"/>" />
                </form>
                <form method="post" action="<%= request.getContextPath() %>/dspace-admin/metadataexport">
                    <input type="hidden" name="handle" value="<%= item.getHandle() %>" />
                    <input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.general.metadataexport.button"/>" />
                </form>
					<% if(hasVersionButton) { %>       
                	<form method="get" action="<%= request.getContextPath() %>/tools/version">
                    	<input type="hidden" name="itemID" value="<%= item.getID() %>" />                    
                    	<input class="btn btn-default col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.general.version.button"/>" />
                	</form>
                	<% } %> 
                	<% if(hasVersionHistory) { %>			                
                	<form method="get" action="<%= request.getContextPath() %>/tools/history">
                    	<input type="hidden" name="itemID" value="<%= item.getID() %>" />
                    	<input type="hidden" name="versionID" value="<%= history.getVersion(item)!=null?history.getVersion(item).getVersionId():null %>" />                    
                    	<input class="btn btn-info col-md-12" type="submit" name="submit" value="<fmt:message key="jsp.general.version.history.button"/>" />
                	</form>         	         	
					<% } %>
             </div>
          </div>
        </div>
<%      } %>

<%
    if (handle != null)
    {
%>
	<div class="">
		<div class="col-sm-<%= admin_button?"7":"12" %> col-md-<%= admin_button?"8":"12" %> col-lg-<%= admin_button?"9":"12" %>">
		<%		
		if (newVersionAvailable)
		   {
		%>
		<div class="alert alert-warning"><b><fmt:message key="jsp.version.notice.new_version_head"/></b>		
		<fmt:message key="jsp.version.notice.new_version_help"/><a href="<%=latestVersionURL %>"><%= latestVersionHandle %></a>
		</div>
		<%
		    }
		%>
		
		<%		
		if (showVersionWorkflowAvailable)
		   {
		%>
		<div class="alert alert-warning"><b><fmt:message key="jsp.version.notice.workflow_version_head"/></b>		
		<fmt:message key="jsp.version.notice.workflow_version_help"/>
		</div>
		<%
		    }
		%>
		

                <%-- <strong>Please use this identifier to cite or link to this item:
                <code><%= HandleManager.getCanonicalForm(handle) %></code></strong>--%>
                <div class="well"><fmt:message key="jsp.display-item.identifier"/>
                <code><%= HandleManager.getCanonicalForm(handle) %></code></div>
       </div>         


<%
    }

    String displayStyle = (displayAll ? "full" : "");
%>
</div>
<div class="">
<div id="wrapperDisplayItem" class="col-lg-9">
    <dspace:item-preview item="<%= item %>" />
    <dspace:item item="<%= item %>" collections="<%= collections %>" style="<%= displayStyle %>" />
    <%-- SFX Link --%>
<%
    if (ConfigurationManager.getProperty("sfx.server.url") != null)
    {
        String sfximage = ConfigurationManager.getProperty("sfx.server.image_url");
        if (sfximage == null)
        {
            sfximage = request.getContextPath() + "/image/sfx-link.gif";
        }
%>
        <a class="btn btn-default" href="<dspace:sfxlink item="<%= item %>"/>" /><img src="<%= sfximage %>" border="0" alt="SFX Query" /></a>
<%
    }
%>

<%
    String locationLink = request.getContextPath() + "/handle/" + handle;

    if (displayAll)
    {
%>
<%
        if (workspace_id != null)
        {
%>
    <form class="col-md-2" method="post" action="<%= request.getContextPath() %>/view-workspaceitem">
        <input type="hidden" name="workspace_id" value="<%= workspace_id.intValue() %>" />
        <input class="btn btn-default" type="submit" name="submit_simple" value="<fmt:message key="jsp.display-item.text1"/>" />
    </form>
<%
        }
        else
        {
%>
    <a class="btn btn-default" href="<%=locationLink %>?mode=simple">
        <fmt:message key="jsp.display-item.text1"/>
    </a>
<%
        }
    }
    else
    {
        if (workspace_id != null)
        {
%>
    <form class="col-md-2" method="post" action="<%= request.getContextPath() %>/view-workspaceitem">
        <input type="hidden" name="workspace_id" value="<%= workspace_id.intValue() %>" />
        <input class="btn btn-default" type="submit" name="submit_full" value="<fmt:message key="jsp.display-item.text2"/>" />
    </form>
<%
        }
        else
        {
%>
    <a class="btn btn-default" href="<%=locationLink %>?mode=full" style="display: none;">
        <fmt:message key="jsp.display-item.text2"/>
    </a>
<%
        }
    }

    if (workspace_id != null)
    {
%>
   <form class="col-md-2" method="post" action="<%= request.getContextPath() %>/workspace">
        <input type="hidden" name="workspace_id" value="<%= workspace_id.intValue() %>"/>
        <input class="btn btn-primary" type="submit" name="submit_open" value="<fmt:message key="jsp.display-item.back_to_workspace"/>"/>
    </form>
<%
    } else {

		if (suggestLink)
        {
%>
    <a class="btn btn-success" href="<%= request.getContextPath() %>/suggest?handle=<%= handle %>" target="_blank">
       <fmt:message key="jsp.display-item.suggest"/>
    </a>
<%
        }
%>
</div>
<div class="col-lg-3">
<div class="row">
<c:forEach var="metricType" items="${metricTypes}">
<c:set var="metricNameKey">
	jsp.display-item.citation.${metricType}
</c:set>
<c:set var="metricIconKey">
	jsp.display-item.citation.${metricType}.icon
</c:set>
<c:if test="${not empty metrics[metricType].counter and metrics[metricType].counter gt 0}">
	<c:if test="${!empty metrics[metricType].moreLink}">
		<script type="text/javascript">
		j(document).ready(function() {
			var obj = JSON.parse('${metrics[metricType].moreLink}');
			j( "div" ).data( "moreLink", obj );
			j( "#metric-counter-${metricType}" ).wrap(function() {
				  return "<a target='_blank' href='" + j( "div" ).data( "moreLink" ).link + "'></a>";
			}).append(" <i class='fa fa-info-circle' data-toggle='tooltip' title='Get updated citations from database'></i>");
			
			jQuery('[data-toggle="tooltip"]').tooltip();
		});
		</script>
	</c:if>
<div class="col-lg-12 col-md-4 col-sm-6 col-xs-12 box-${metricType}">
<div class="media ${metricType}">
	<div class="media-left">
		<fmt:message key="${metricIconKey}"/>
	</div>
	<div class="media-body text-center">
		<h4 class="media-heading"><fmt:message key="${metricNameKey}"/>
		<c:if test="${not empty metrics[metricType].rankingLev}">
		<span class="pull-right">
		<fmt:message key="jsp.display-item.citation.top"/>		
		<span class="metric-ranking arc">
			<span class="circle" data-toggle="tooltip" data-placement="bottom" 
				title="<fmt:message key="jsp.display-item.citation.${metricType}.ranking.tooltip"><fmt:param><fmt:formatNumber value="${metrics[metricType].rankingLev}" type="NUMBER" maxFractionDigits="0" /></fmt:param></fmt:message>">
				<fmt:formatNumber value="${metrics[metricType].rankingLev}" 
					type="NUMBER" maxFractionDigits="0" />
			</span>
		</span>
		</span>
		</c:if>
		</h4>
		<span id="metric-counter-${metricType}" class="metric-counter"><fmt:formatNumber value="${metrics[metricType].counter}" type="NUMBER" maxFractionDigits="0" /></span>
	</div>
	<c:if test="${not empty metrics[metricType].last1}">
	<div class="row">
		<div class="col-xs-6 text-left">
			<fmt:message key="jsp.display-item.citation.last1" />
			<br/><fmt:formatNumber value="${metrics[metricType].last1}" type="NUMBER" maxFractionDigits="0" /></div>
		<div class="col-xs-6 text-right">
			<fmt:message key="jsp.display-item.citation.last2" />
			<br/><fmt:formatNumber value="${metrics[metricType].last2}" type="NUMBER" maxFractionDigits="0" /></div>
	</div>
	</c:if>
	<div class="row">
		<div class="col-lg-12 text-center small">
			<fmt:message
				key="jsp.display-item.citation.time">
				<fmt:param value="${metrics[metricType].time}" />
			</fmt:message>
		</div>
	</div>
	</div>
</div>
</c:if>
</c:forEach>
    <%
	   if(scholarEnabled) { %>
<div class="col-lg-12 col-md-4 col-sm-6" style="display: none;">
<div class="media google">
	<div class="media-left">
		<fmt:message key="jsp.display-item.citation.google.icon"/>
	</div>
	<div id="googleCitedResult" class="media-body text-center" >
		<h4 class="media-heading"><fmt:message key="jsp.display-item.citation.google"/></h4>
		
		
   		    <span class="metric-counter"><a data-toggle="tooltip" target="_blank" title="<fmt:message key="jsp.display-item.citation.google.tooltip"/>" href="https://scholar.google.com/scholar?as_q=&as_epq=<%= title %>&as_occt=any"><fmt:message key="jsp.display-item.citation.google.check"/></a></span>
	</div>
</div>	
</div>
<br class="visible-lg" />
    <% }
	   if(altMetricEnabled) { %>
<div class="col-lg-12 col-md-4 col-sm-6">
<div class="media altmetric">
	<div class="media-left">
      		<div class='altmetric-embed' data-hide-no-mentions="true" data-badge-popover="right" data-badge-type="donut" data-link-target='_blank' data-doi="<%= doi %>"></div>
	</div>
	<div class="media-body media-middle text-center">
		<h4 class="media-heading"><fmt:message key="jsp.display-item.citation.altmetric"/></h4>
	</div>
</div>
</div>
<% } %>
    </div>
</div>
<% if(pmcEnabled) { %>
<div class="modal fade" id="dialogPMC" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">

    </div>
  </div>
</div>
<% }%>
</div>

<%
    }
%>
</div>

<div class="container">
    <%-- Versioning table --%>
<%
    if (versioningEnabled && hasVersionHistory)
    {
        boolean item_history_view_admin = ConfigurationManager
                .getBooleanProperty("versioning", "item.history.view.admin");
        if(!item_history_view_admin || admin_button) {         
%>
	<div id="versionHistory" class="panel panel-info">
	<div class="panel-heading"><fmt:message key="jsp.version.history.head2" /></div>
	
	<table class="table panel-body">
		<tr>
			<th id="tt1" class="oddRowEvenCol"><fmt:message key="jsp.version.history.column1"/></th>
			<th 			
				id="tt2" class="oddRowOddCol"><fmt:message key="jsp.version.history.column2"/></th>
			<th 
				 id="tt3" class="oddRowEvenCol"><fmt:message key="jsp.version.history.column3"/></th>
			<th 
				
				id="tt4" class="oddRowOddCol"><fmt:message key="jsp.version.history.column4"/></th>
			<th 
				 id="tt5" class="oddRowEvenCol"><fmt:message key="jsp.version.history.column5"/> </th>
		</tr>
		
		<% for(Version versRow : historyVersions) {  
		
			EPerson versRowPerson = versRow.getEperson();
			String[] identifierPath = VersionUtil.addItemIdentifier(item, versRow);
		%>	
		<tr>			
			<td headers="tt1" class="oddRowEvenCol"><%= versRow.getVersionNumber() %></td>
			<td headers="tt2" class="oddRowOddCol"><a href="<%= request.getContextPath() + identifierPath[0] %>"><%= identifierPath[1] %></a><%= item.getID()==versRow.getItemID()?"<span class=\"glyphicon glyphicon-asterisk\"></span>":""%></td>
			<td headers="tt3" class="oddRowEvenCol"><% if(admin_button) { %><a
				href="mailto:<%= versRowPerson.getEmail() %>"><%=versRowPerson.getFullName() %></a><% } else { %><%=versRowPerson.getFullName() %><% } %></td>
			<td headers="tt4" class="oddRowOddCol"><%= versRow.getVersionDate() %></td>
			<td headers="tt5" class="oddRowEvenCol"><%= versRow.getSummary() %></td>
		</tr>
		<% } %>
	</table>
	<div class="panel-footer"><fmt:message key="jsp.version.history.legend"/></div>
	</div>
<%
        }
    }
%>
<br/>
    <%-- Create Commons Link --%>
<%
    if (cc_url != null)
    {
%>
    <p class="text-center alert alert-info"><fmt:message key="jsp.display-item.text3"/> <a href="<%= cc_url %>"><fmt:message key="jsp.display-item.license"/></a>
    <a href="<%= cc_url %>"><img src="<%= request.getContextPath() %>/image/cc-somerights.gif" border="0" alt="Creative Commons" style="margin-top: -5px;" class="pull-right"/></a>
    </p>
    <!--
    <%= cc_rdf %>
    -->
<%
    } else {
%>
    <p class="text-center alert alert-info"><fmt:message key="jsp.display-item.copyright"/></p>
<%
    } 
%>
	</div>    
</dspace:layout>
