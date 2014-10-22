#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ssl.h"

/*******************************/
/* Local Static Vars           */
/*******************************/

static SV *my_callback; /* Pointer To Function for Registered Callback */
char up[2];
char down[4];


/******************************/
/* local callback             */
/******************************/
static SSL_EVENT_RETCODE
my_callback_function(int Channel, SSL_EVENT_TYPE Event, SSL_EVENT_INFO* EventInfo, void *ClientEventTag)
{
	dSP;
	int count;
	int retval;
	HV * hImage = (HV*)NULL;
	ENTER;SAVETMPS;
	PUSHMARK(SP);
	if (hImage == (HV*)NULL)
		hImage = newHV();
	hv_clear(hImage);
	if (Event == SSL_ET_ITEM_IMAGE)
	{
		SSL_ITEM_IMAGE_TYPE  * item = (SSL_ITEM_IMAGE_TYPE *)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"SequenceNum",11,newSViv(item->SequenceNum),0);
		hv_store(hImage,"PreviousName",12,newSVpv(item->PreviousName,strlen(item->PreviousName)),0);
		hv_store(hImage,"NextName",8,newSVpv(item->NextName,strlen(item->NextName)),0);
		hv_store(hImage,"GroupId",7,newSViv(item->GroupId),0);
		hv_store(hImage,"ItemState",8,newSViv(item->ItemState),0);
		hv_store(hImage,"StateInfoCode",13,newSViv(item->StateInfoCode),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	if (Event == SSL_ET_ITEM_UPDATE)
	{
		SSL_ITEM_UPDATE_TYPE *item = (SSL_ITEM_UPDATE_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	if (Event == SSL_ET_SERVICE_INFO)
	{
		SSL_SERVICE_INFO_TYPE *item = (SSL_SERVICE_INFO_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		/* switch (item->ServiceStatus)
		{
			SSL_SS_SERVER_DOWN:
			hv_store(hImage,"ServiceStatus",13,newSVpv(down,4),0);
			SSL_SS_SERVER_UP:
			hv_store(hImage,"ServiceStatus",13,newSVpv(up,2),0);
		}
		*/
		hv_store(hImage,"ServiceStatus",13,newSViv((int)item->ServiceStatus),0);
	}
	if (Event == SSL_ET_ITEM_STATUS_STALE || Event == SSL_ET_ITEM_STATUS_OK 
		|| Event == SSL_ET_ITEM_STATUS_CLOSED || Event == SSL_ET_ITEM_STATUS_CLOSED_RECOVER
		|| Event == SSL_ET_ITEM_STATUS_INFO )
	{
		SSL_ITEM_STATUS_TYPE *item = (SSL_ITEM_STATUS_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"ItemName",8,newSVpv(item->ItemName,strlen(item->ItemName)),0);
		hv_store(hImage,"StateInfoCode",13,newSViv(item->StateInfoCode),0);
		hv_store(hImage,"Text",4,newSVpv(item->Text,strlen(item->Text)),0);
	}
	if (Event == SSL_ET_INSERT_ACK || Event == SSL_ET_INSERT_NAK )
	{
		SSL_INSERT_RESPONSE_TYPE *item = (SSL_INSERT_RESPONSE_TYPE*)EventInfo;
		hv_store(hImage,"ServiceName",11,newSVpv(item->ServiceName,strlen(item->ServiceName)),0);
		hv_store(hImage,"InsertName",10,newSVpv(item->InsertName,strlen(item->InsertName)),0);
		hv_store(hImage,"DataLength",10,newSViv(item->DataLength),0);
		hv_store(hImage,"Data",4,newSVpv(item->Data,item->DataLength),0);
	}
	EXTEND (SP, 3);
	XPUSHs (sv_2mortal (newSViv (     Channel)));
	XPUSHs (sv_2mortal (newSViv (     Event  )));
	XPUSHs (sv_2mortal (newRV   ((SV*)hImage )));
	
	PUTBACK;
	count = perl_call_sv(my_callback, G_SCALAR);
	SPAGAIN;

	if ( count!= 1 )
		croak ("perl-my_callback returned more than one argument\n");
	retval = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;
}


MODULE = Reuters::SSL		PACKAGE = Reuters::SSL		

BOOT:
printf("Initializing Reuters SSL Library\n");
my_callback = newSVsv (&PL_sv_undef);
strcpy (up, "UP");
strcpy (down, "DOWN");


int
sslInit()
	CODE:
	RETVAL = sslInit(SSL_VERSION_NO);
	OUTPUT:
	RETVAL

int
sslSnkMount(UserName)
	char *UserName;
	CODE:
	RETVAL = sslSnkMount(UserName);
	OUTPUT:
	RETVAL

int
sslDismount(Channel)
	int Channel;
	CODE:
	RETVAL = sslDismount(Channel);

int
sslSnkOpen(Channel, ServiceName, ItemName)
	int Channel;
	char *ServiceName;
	char *ItemName;
	CODE:
	RETVAL = sslSnkOpen(Channel, ServiceName, ItemName, NULL, NULL);
	OUTPUT:
	RETVAL

int 
sslRegisterCallBack(Channel, EventType, Callback)
	int Channel;
	int EventType;
	SV* Callback;
	CODE:
	sv_setsv (my_callback, Callback);
	EventType = SSL_EC_DEFAULT_HANDLER;
	RETVAL = sslRegisterClassCallBack(Channel, EventType, my_callback_function, NULL);
	OUTPUT:
	RETVAL

int
sslSnkClose(Channel, ServiceName, ItemName)
	int Channel;
	char *ServiceName;
	char *ItemName;
	CODE:
	RETVAL = sslSnkClose(Channel, ServiceName, ItemName);
	OUTPUT:
	RETVAL

int
sslDispatchEvent(Channel, maxEvents)
	int Channel;
	int maxEvents;
	PREINIT:
	fd_set readfs;
	struct timeval timeout;
	CODE:
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	FD_ZERO(&readfs);
	if (Channel != -1)
		FD_SET(Channel, &readfs);
	select(FD_SETSIZE, &readfs,NULL,NULL,&timeout);
	RETVAL = sslDispatchEvent(Channel, maxEvents);
	OUTPUT:
	RETVAL

int
sslGetProperty(Channel, OptionCode)
	int Channel;
	int OptionCode;
	PREINIT:
	int optionValue;
	int* optionPointer;
	int retval;
	PPCODE:
	optionPointer = &optionValue;
	retval = sslGetProperty(Channel, OptionCode, optionPointer);
	EXTEND(SP, 2);
	PUSHs(sv_2mortal(newSViv(retval)));
	PUSHs(sv_2mortal(newSViv(optionValue)));

char *
sslGetErrorText(Channel)
	int Channel;
	CODE:
	RETVAL = sslGetErrorText(Channel);
	OUTPUT:
	RETVAL

int
sslPostEvent(Channel, EventType, pEventInfo)
	int Channel;
	int EventType;
	SV* pEventInfo;
	PREINIT:
	SSL_INSERT_TYPE item;
	HV * EventInfo;
	STRLEN len;
	CODE:
	EventInfo = (HV*)SvRV(pEventInfo);
	item.Data =        (char*)SvPV(*hv_fetch(EventInfo,"Data"       , 4,0),len);
	item.ServiceName = (char*)SvPV(*hv_fetch(EventInfo,"ServiceName",11,0),len);
	item.InsertName  = (char*)SvPV(*hv_fetch(EventInfo,"InsertName" ,10,0),len);
	item.InsertTag = NULL;
	item.DataLength =         SvIV(*hv_fetch(EventInfo,"DataLength", 10,0));
	/*
	printf("[XS::sslPostEvent] InsertName :%s\n",item.InsertName);
	printf("[XS::sslPostEvent] ServiceName:%s\n",item.ServiceName);
	printf("[XS::sslPostEvent] DataLength:%d\n",item.DataLength);
	printf("[XS::sslPostEvent] Data      :%s\n",item.Data);
	*/
	RETVAL = sslPostEvent(Channel, (SSL_EVENT_TYPE)EventType, &item);
	OUTPUT:
	RETVAL
