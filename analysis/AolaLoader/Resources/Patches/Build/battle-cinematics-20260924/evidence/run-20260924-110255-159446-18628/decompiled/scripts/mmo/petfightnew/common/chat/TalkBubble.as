package mmo.petfightnew.common.chat
{
   import flash.display.Sprite;
   import mmo.petfightnew.common.FightController;
   import mmo.play.player.talkable.ITalkable;
   import mmo.play.player.talkable.command.FightTalkFaceCommand;
   import mmo.util.command.ISceneCommand;
   import mmo.util.command.SceneCommandEvent;
   
   public class TalkBubble implements ITalkable
   {
      
      private var _playerSprite:Sprite;
      
      private var _scale:Number = 1;
      
      private var _isFace:Boolean;
      
      private var _commandList:Array;
      
      private var _contentList:Array;
      
      public function TalkBubble(param1:Sprite, param2:Number, param3:Boolean)
      {
         super();
         this._playerSprite = param1;
         this._scale = param2;
         this._isFace = param3;
      }
      
      public function say(param1:String, param2:int = -1) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         if(this.isOnlyFace(param1))
         {
            this.fightTalkFace(parseInt(param1.split("#")[1]));
         }
         else
         {
            _loc3_ = "play_res";
            _loc4_ = "mmo.play_res.scenetalk.TalkContainer";
            _loc5_ = {};
            _loc5_["url"] = _loc3_;
            _loc5_["className"] = _loc4_;
            _loc5_["player"] = this._playerSprite;
            _loc5_["scale"] = this._scale;
            _loc5_["message"] = param1;
            _loc5_["second"] = param2;
            if(this._commandList != null)
            {
               (this._commandList[0] as ISceneCommand).cancel();
               this._commandList = null;
               this._contentList = null;
            }
            this.pushCommand(SayingCommand,_loc5_);
         }
      }
      
      public function isOnlyFace(param1:String) : Boolean
      {
         var _loc2_:RegExp = /^#\d+$/;
         return _loc2_.test(param1);
      }
      
      public function smile(param1:int) : void
      {
      }
      
      public function fightTalkFace(param1:int) : void
      {
         var _loc2_:String = "play_res";
         var _loc3_:Object = {};
         _loc3_["url"] = _loc2_;
         _loc3_["isFace"] = this._isFace;
         var _loc4_:String = "mmo.play_res.scenetalk.PetSmilingContainer" + (this._isFace ? 0 : 1);
         _loc3_["className"] = _loc4_;
         _loc3_["player"] = FightController.instance.fightPanel.layerTop;
         _loc3_["faceId"] = param1;
         _loc3_["isFightTalkFace"] = true;
         if(this._commandList != null)
         {
            (this._commandList[0] as ISceneCommand).cancel();
            this._commandList = null;
            this._contentList = null;
         }
         this.pushCommand(FightTalkFaceCommand,_loc3_);
      }
      
      public function dispose() : void
      {
         if(this._commandList != null)
         {
            (this._commandList[0] as ISceneCommand).cancel();
            this._commandList = null;
            this._contentList = null;
         }
         this._playerSprite = null;
      }
      
      private function pushCommand(param1:Class, param2:Object) : void
      {
         if(this._commandList == null)
         {
            this._commandList = [];
            this._contentList = [];
         }
         var _loc3_:ISceneCommand = new param1();
         this._commandList.push(_loc3_);
         this._contentList.push(param2);
         if(this._commandList.length == 1)
         {
            _loc3_.addEventListener(SceneCommandEvent.SUCCEED,this.onCommandSucceed,false,0,true);
            _loc3_.execute(param2);
         }
      }
      
      private function nextCommand() : void
      {
         var _loc1_:ISceneCommand = null;
         var _loc2_:Object = null;
         if(this._commandList.length > 0)
         {
            _loc1_ = this._commandList[0];
            _loc2_ = this._contentList[0];
            _loc1_.addEventListener(SceneCommandEvent.SUCCEED,this.onCommandSucceed,false,0,true);
            _loc1_.execute(_loc2_);
         }
         else
         {
            this._commandList = null;
            this._contentList = null;
         }
      }
      
      private function onCommandSucceed(param1:SceneCommandEvent) : void
      {
         this._commandList.shift();
         this._contentList.shift();
         this.nextCommand();
      }
   }
}

