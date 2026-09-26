package mmo.petfightnew.common.startmovie
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.member.MemberTypes;
   import mmo.common.user.UserInfo;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.MemberClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.PreLoadAssetsUtil;
   
   public class FightIconRegister extends EventDispatcher
   {
      
      public static const LOAD_DONE:String = "LOAD_DONE";
      
      private var info:PlayerBattleInfo;
      
      private var icon:Sprite;
      
      private var isMe:Boolean = false;
      
      private var isMember:Boolean = false;
      
      private var loading:MovieClip;
      
      private const CMD_GET_NAME_BY_ID:String = "getNameById";
      
      public function FightIconRegister(param1:PlayerBattleInfo, param2:Sprite)
      {
         super();
         this.info = param1;
         this.icon = param2;
         this.isMe = param1.PMMasterId == UserInfo.userId ? true : false;
         this.icon.cacheAsBitmap = true;
         this.init();
      }
      
      private function init() : void
      {
         this.initIcon();
         this.initLoading();
         this.initName();
      }
      
      private function initIcon() : void
      {
         var _loc1_:int = 0;
         if(this.isMe)
         {
            MovieClip(this.icon.getChildByName("icon")).gotoAndStop(1);
         }
         else if(FightData.instance.challengeNpcId > 0)
         {
            this.getNpcIcon();
         }
         else
         {
            _loc1_ = Math.random() * 2 + 2;
            MovieClip(this.icon.getChildByName("icon")).gotoAndStop(_loc1_);
         }
         MovieClip(this.icon.getChildByName("mcBlue")).visible = false;
         if(this.info.PMMasterId > 0)
         {
            this.getMemberType();
         }
      }
      
      private function getMemberType() : void
      {
         SocketClient.instance.addEventListener(MemberClient.onGetUserMemberType,this.onGetType);
         MemberClient.instance.getMemberTypeByUserId(this.info.PMMasterId);
      }
      
      private function onGetType(param1:SocketClientEvent) : void
      {
         if(param1.params.userId != this.info.PMMasterId)
         {
            return;
         }
         SocketClient.instance.removeEventListener(MemberClient.onGetUserMemberType,this.onGetType);
         var _loc2_:int = int(param1.params.memberType);
         this.isMember = MemberTypes.compareMemberType(_loc2_,MemberTypes.Member);
         if(this.isMember)
         {
            MovieClip(this.icon.getChildByName("mcBlue")).visible = true;
         }
      }
      
      private function getNpcIcon() : void
      {
         var _loc2_:Class = null;
         var _loc3_:DisplayObject = null;
         var _loc4_:int = 0;
         var _loc1_:String = "mmo.petfightnew.npc" + FightData.instance.challengeNpcId.toString();
         if(ApplicationDomain.currentDomain.hasDefinition(_loc1_))
         {
            _loc2_ = ApplicationDomain.currentDomain.getDefinition(_loc1_) as Class;
            _loc3_ = new _loc2_() as DisplayObject;
            MovieClip(this.icon.getChildByName("icon")).gotoAndStop(4);
            MovieClip(this.icon.getChildByName("icon")).addChild(_loc3_);
         }
         else
         {
            _loc4_ = Math.random() * 2 + 2;
            MovieClip(this.icon.getChildByName("icon")).gotoAndStop(_loc4_);
         }
      }
      
      private function initLoading() : void
      {
         var _loc1_:Sprite = this.icon.getChildByName("ok") as Sprite;
         if(_loc1_ != null)
         {
            _loc1_.visible = false;
         }
         this.loading = this.icon.getChildByName("mcLoading") as MovieClip;
         if(!ConfigReader.instance.showOthersFightLoad || this.info.PMMasterId == UserInfo.userId || this.info.PMMasterId < 0)
         {
            this.icon.addEventListener(Event.ENTER_FRAME,this.onFrame);
            this.icon.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemove);
         }
         else
         {
            SocketClient.instance.addEventListener(SendLoadingHelper.CMD_FIGHT_LOAD,this.onLoaded);
         }
      }
      
      private function onFrame(param1:Event) : void
      {
         var _loc2_:Number = NaN;
         if(PreLoadAssetsUtil.instance.isLoading)
         {
            this.setLoading(PreLoadAssetsUtil.instance.progress);
         }
         else if(PreLoadAssetsUtil.instance.progress >= 1)
         {
            _loc2_ = PreLoadAssetsUtil.instance.progress;
            this.setLoading(_loc2_);
            this.icon.removeEventListener(Event.ENTER_FRAME,this.onFrame);
         }
      }
      
      private function onRemove(param1:Event) : void
      {
         this.icon.removeEventListener(Event.ENTER_FRAME,this.onFrame);
         SocketClient.instance.removeEventListener(SendLoadingHelper.CMD_FIGHT_LOAD,this.onLoaded);
      }
      
      private function onLoaded(param1:SocketClientEvent) : void
      {
         var _loc5_:Number = NaN;
         var _loc2_:String = param1.params.msg;
         var _loc3_:Array = _loc2_.split(":");
         var _loc4_:int = int(_loc3_[0]);
         if(_loc4_ == this.info.PMMasterId)
         {
            _loc5_ = Number(_loc3_[1]);
            this.setLoading(_loc5_);
         }
      }
      
      private function setLoading(param1:Number) : void
      {
         var _loc3_:Sprite = null;
         var _loc2_:int = this.loading.totalFrames * param1;
         this.loading.gotoAndStop(_loc2_);
         if(_loc2_ == this.loading.totalFrames)
         {
            _loc3_ = this.icon.getChildByName("ok") as Sprite;
            if(_loc3_ != null)
            {
               _loc3_.visible = true;
            }
         }
         if(param1 >= 1 && this.info.PMMasterId > 0 && this.info.PMMasterId != UserInfo.userId)
         {
            dispatchEvent(new Event(LOAD_DONE));
         }
      }
      
      private function initName() : void
      {
         var _loc3_:String = null;
         var _loc1_:TextField = this.icon.getChildByName("txtName") as TextField;
         var _loc2_:IUserNameManager = ServiceContainer.getService("UserNameManager") as IUserNameManager;
         if(this.isMe)
         {
            _loc1_.text = _loc2_.getNickName(UserInfo.userName);
         }
         else if(FightData.instance.challengeNpcId > 0)
         {
            _loc3_ = FightData.instance.npcName;
            _loc1_.text = _loc3_;
         }
         else if(this.info.PMMasterId < 0)
         {
            _loc1_.text = "";
         }
         else
         {
            this.getNameById(this.info.PMMasterId);
         }
      }
      
      private function getNameById(param1:int) : void
      {
         SocketClient.instance.addEventListener(this.CMD_GET_NAME_BY_ID,this.onGetNameById);
         this.getNameByIds([param1]);
      }
      
      private function getNameByIds(param1:Array) : void
      {
         var _loc2_:* = "";
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            if(_loc3_ > 0)
            {
               _loc2_ += ",";
            }
            _loc2_ += param1[_loc3_];
            _loc3_++;
         }
         SocketClient.instance.sendXtMessage("UserExtension",this.CMD_GET_NAME_BY_ID,{"ids":_loc2_});
      }
      
      private function onGetNameById(param1:SocketClientEvent) : void
      {
         if(param1.params.id2name[0].id != this.info.PMMasterId)
         {
            return;
         }
         SocketClient.instance.removeEventListener(this.CMD_GET_NAME_BY_ID,this.onGetNameById);
         var _loc2_:Array = param1.params.id2name;
         var _loc3_:String = _loc2_[0].n;
         var _loc4_:int = int(_loc3_.indexOf("|"));
         var _loc5_:String = _loc3_.substring(_loc4_ + 1,_loc3_.length);
         TextField(this.icon.getChildByName("txtName")).text = _loc5_;
      }
   }
}

