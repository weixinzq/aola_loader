package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetFightClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.antiaddiction.IAntiAddiction;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.interfaces.user.UserNameEvent;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol166")]
   public class GotChallengePanel extends Sprite
   {
      
      public var btnCancel:SimpleButton;
      
      public var btnOK:SimpleButton;
      
      public var mcType:MovieClip;
      
      public var txtMyName:TextField;
      
      public var txtVSName1:TextField;
      
      public var txtVSName2:TextField;
      
      private var challenger:String;
      
      private var nameService:IUserNameManager;
      
      private var petDataService:IPetDataService;
      
      private var canSwitch:Boolean;
      
      private var _isTerritoryFight:Boolean;
      
      private var _fightType:int;
      
      private var _isYiJieShuangChong:Boolean;
      
      private var _notifyParam:Object;
      
      public function GotChallengePanel(param1:String, param2:Boolean, param3:int, param4:Object)
      {
         super();
         this.challenger = param1;
         this.canSwitch = param2;
         this._fightType = param3;
         this._notifyParam = param4;
         this._isTerritoryFight = param3 == 1;
         this._isYiJieShuangChong = param3 == 2;
         this.petDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         this.nameService = ServiceContainer.instance.getService("UserNameManager") as IUserNameManager;
         this.nameService.addEventListener(UserNameEvent.getNicknameByName,this.onGetNickName);
         this.nameService.getNicknameByName(param1);
         if(this._isYiJieShuangChong)
         {
            MovieClip(this.mcType).gotoAndStop(3);
         }
         else if(param2)
         {
            MovieClip(this.mcType).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.mcType).gotoAndStop(1);
         }
         var _loc5_:String = this.nameService.getNickName(UserInfo.userName);
         TextField(this.txtMyName).text = _loc5_;
         SimpleButton(this.btnOK).addEventListener(MouseEvent.CLICK,this.onOK);
         SimpleButton(this.btnCancel).addEventListener(MouseEvent.CLICK,this.onCancel);
         this.initMe();
      }
      
      private function initMe() : void
      {
         var _loc4_:int = 0;
         var _loc5_:PetBriefInfo = null;
         if(!this._isYiJieShuangChong)
         {
            return;
         }
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc2_:Array = _loc1_.getMyPets();
         var _loc3_:String = "";
         if(_loc2_.length < 4)
         {
            _loc3_ = "开启挑战背包至少需要4只使用新技能的亚比。";
         }
         else
         {
            _loc3_ = "";
            _loc4_ = 0;
            while(_loc4_ < _loc2_.length)
            {
               _loc5_ = _loc2_[_loc4_];
               if(!_loc5_.isUsingGQNewSkill())
               {
                  _loc3_ = "背包有非新技能组的亚比";
                  break;
               }
               _loc4_++;
            }
         }
         ActComHelper.refreshObj(this,"btnOK",_loc3_ != "",_loc3_,"");
      }
      
      private function onAccept(param1:SocketClientEvent) : void
      {
         var _loc2_:Object = null;
         SocketClient.instance.removeEventListener(PetFightClient.cmdAccept,this.onAccept);
         if(!param1.params.res)
         {
            NewDialog.showFailMessage("很遗憾，对方已经退出对战了！");
         }
         else if(this._isYiJieShuangChong)
         {
            _loc2_ = this._notifyParam;
            Panel_Helper.loadResAndShow("activityres/activity240208/yijieshuangchongduizhan/yijieshuangchongduizhan_code","mmo.activity240208.yijieshuangchongduizhan.panel.YJSCDZ_MainPl",_loc2_);
         }
      }
      
      private function onGetNickName(param1:UserNameEvent) : void
      {
         this.nameService.removeEventListener(UserNameEvent.getNicknameByName,this.onGetNickName);
         var _loc2_:String = this.nameService.getNickName(this.challenger);
         TextField(this.txtVSName1).text = _loc2_;
         TextField(this.txtVSName2).text = _loc2_;
      }
      
      private function onOK(param1:MouseEvent) : void
      {
         if(Boolean(param1.target.hasOwnProperty("enabled")) && !param1.target.enabled)
         {
            return;
         }
         this.close();
         if(!this.hasAvailableTime())
         {
            PetFightClient.instance.refuse(this.challenger);
            return;
         }
         if(this.hasAvailablePet())
         {
            SocketClient.instance.addEventListener(PetFightClient.cmdAccept,this.onAccept);
            PetFightClient.instance.accept(this.challenger,this.canSwitch);
         }
         else
         {
            NewDialog.showFailMessage("你没有可进行作战的亚比！");
            PetFightClient.instance.refuse(this.challenger);
         }
      }
      
      private function hasAvailableTime() : Boolean
      {
         if(this.getAvailableTime() <= 0)
         {
            NewDialog.showFailMessage("小奥拉今天的体力消耗很大，无法进行对战，还是进行一些轻松的活动吧！");
            return false;
         }
         return true;
      }
      
      private function getAvailableTime() : int
      {
         var _loc1_:IAntiAddiction = ServiceContainer.getService(IAntiAddiction) as IAntiAddiction;
         return int(_loc1_.getAvailableTime());
      }
      
      private function hasAvailablePet() : Boolean
      {
         var _loc1_:PetBriefInfo = null;
         for each(_loc1_ in this.petDataService.getMyPets())
         {
            if(_loc1_.curHp > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      private function onCancel(param1:MouseEvent) : void
      {
         SocketClient.instance.removeEventListener(PetFightClient.cmdAccept,this.onAccept);
         PetFightClient.instance.refuse(this.challenger);
         this.close();
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}

